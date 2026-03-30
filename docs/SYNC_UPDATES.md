# Offline-First List Synchronization with Supabase

## 1. Overview

This document describes the technical implementation of offline-first sync architecture for shopping list operations. When the device is offline, all list mutations (creating a list, renaming a list) are persisted locally in a queue. When connectivity is restored, the app automatically detects the reconnection event and replays all queued operations against Supabase in the correct order, handling retries on transient failures and cleaning up successfully synced entries.

The architecture follows an **optimistic update** pattern: local state is updated immediately so the UI is never blocked, and Supabase sync happens asynchronously in the background.

---

## 2. New Files Created

### `lib/features/shopping_list/models/pending_operation.dart`

**Purpose:** Immutable model representing a single pending sync operation that needs to be replayed when the device comes back online.

**Key fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Unique identifier for deduplication (e.g., `op-1711234567890`) |
| `type` | `PendingOperationType` | Enum: `createList` or `renameList` |
| `payload` | `Map<String, dynamic>` | Operation-specific data (see Section 5) |
| `timestamp` | `DateTime` | When the operation was created |
| `retryCount` | `int` | Number of failed sync attempts (default: 0) |

**Serialization:** Implements `toJson()` / `fromJson()` for SharedPreferences persistence. The `type` field is serialized as the enum's `.name` string.

---

### `lib/features/shopping_list/data/sync_queue_repository.dart`

**Purpose:** Repository wrapping `SharedPreferences` to persist and load the pending operations queue. Uses the key `pending_sync_queue`.

**Key methods:**

| Method | Description |
|--------|-------------|
| `loadQueue()` | Loads all pending operations from storage |
| `saveQueue(List<PendingOperation>)` | Overwrites the entire queue in storage |
| `enqueue(PendingOperation)` | Appends a new operation to the end of the queue |
| `remove(String operationId)` | Removes a successfully synced operation by ID |
| `updateRetryCount(String operationId, int newCount)` | Increments retry count for a failed operation |
| `clear()` | Clears all pending operations (used in tests) |

**Factory:** `SyncQueueRepository.create()` — async factory that initializes `SharedPreferences` internally.

---

### `lib/core/services/sync_service.dart`

**Purpose:** Central service managing offline-to-online sync. Listens to connectivity changes and processes the pending operations queue sequentially when the device comes back online.

**Key properties:**

| Property | Type | Description |
|----------|------|-------------|
| `status` | `SyncStatusState` | Current sync state: `idle`, `syncing`, or `error` |
| `pendingCount` | `int` | Number of operations waiting to be synced |
| `lastError` | `String?` | Human-readable error message for the last permanent failure |
| `maxRetries` | `static const int = 3` | Maximum retry attempts before marking an operation as permanently failed |

**Key methods:**

| Method | Description |
|--------|-------------|
| `initialize()` | Subscribes to `connectivity_plus` stream and loads initial pending count |
| `enqueue(PendingOperation)` | Adds an operation to the queue; triggers immediate sync if online |
| `processQueue()` | Processes all pending operations sequentially; skips if already processing or offline |
| `dispose()` | Cancels the connectivity subscription |

**Connectivity:** Uses `connectivity_plus` package. The `onConnectivityChanged` stream emits `List<ConnectivityResult>` (v6+ API). The service takes the last result in the list to determine current connectivity.

---

### `lib/features/shopping_list/services/supabase_list_service.dart`

**Purpose:** Service for Supabase CRUD operations on the `public.listas_do_usuario` table.

**Methods:**

| Method | Description |
|--------|-------------|
| `insertManualList({userId, name, descricao?, moeda?})` | Inserts a new list row; returns the full row including DB-generated `id` |
| `updateListName(String listId, String newName)` | Updates the `nome` column for a given list `id` |

---

## 3. Modified Files

### `pubspec.yaml`

Added `connectivity_plus: ^6.0.0` to `dependencies`.

---

### `lib/features/shopping_list/state/shopping_list_controller.dart`

**Changes:**
- Added import for `pending_operation.dart` and `sync_service.dart`
- Added `SyncService? _syncService` field
- Added `setSyncService(SyncService? service)` setter (called from `main.dart`)
- Modified `addShoppingList()`: on Supabase failure, enqueues a `createList` operation instead of rethrowing
- Modified `renameShoppingList()`: on Supabase failure, enqueues a `renameList` operation instead of rethrowing

**Why:** The controller is the central place for sync logic. UI layers remain unaware of sync internals — they simply call controller methods and the controller handles both local persistence and Supabase sync transparently.

---

### `lib/main.dart`

**Changes:**
- Added imports for `SyncQueueRepository` and `SyncService`
- Added `SyncQueueRepository` as a plain `Provider` (initialized in `main()` via `SyncQueueRepository.create()`)
- Added `SyncService` as a `ChangeNotifierProvider`
- Changed `ShoppingListController`'s `ChangeNotifierProxyProvider2` to `ChangeNotifierProxyProvider3` to also depend on `SyncService`
- Calls `syncService.initialize()` on app startup
- Calls `controller.setSyncService(syncService)` on both `create` and `update`

---

### `lib/features/shopping_list/screens/shopping_list_screen.dart`

**Changes:** Removed try/catch blocks from `_showRenameListDialog()` (2 occurrences). Since the controller no longer throws on Supabase failure (it enqueues instead), the UI no longer needs error handling for rename operations.

---

### `lib/features/shopping_list/screens/home_screen.dart`

**Changes:** Same as above — removed try/catch from `_showRenameListDialog()`.

---

### `lib/features/shopping_list/screens/lists_screen.dart`

**Changes:** Same as above — removed try/catch from `_showRenameListDialog()`.

---

### `lib/features/shopping_list/screens/main_screen.dart`

**Changes:** Removed try/catch from `_createList()`. The controller's `addShoppingList()` no longer throws on Supabase failure.

---

### `test/shopping_list_controller_test.dart`

**Changes:** Added `TestWidgetsFlutterBinding.ensureInitialized()` call in `setUp()` to support Flutter binding in unit tests. Added 2 new tests in the "Renomear Lista" group.

---

## 4. Architecture Diagram

```
User Action (create list / rename list)
         │
         ▼
ShoppingListController
  ├── Local state update (SharedPreferences)
  ├── notifyListeners() → UI updates immediately
  └── Try Supabase call
        ├── SUCCESS → Done (synced)
        └── FAILURE
              │
              ▼
         SyncService.enqueue(PendingOperation)
              │
              ▼
         SyncQueueRepository.enqueue()
         (persisted to SharedPreferences)
              │
              ▼
         SyncService checks connectivity
              ├── OFFLINE → Wait for connectivity event
              └── ONLINE → processQueue()
                              │
                              ▼
                         For each operation:
                           ├── Call Supabase
                           ├── SUCCESS → remove from queue
                           └── FAILURE
                                 ├── retryCount < maxRetries → increment, keep in queue
                                 └── retryCount >= maxRetries → remove, emit error state
```

---

## 5. Sync Operation Types

### `createList`

Triggered when `addShoppingList()` fails to persist to Supabase.

**Payload structure:**
```json
{
  "userId": "uuid-of-authenticated-user",
  "name": "Nome da lista",
  "tempId": "list-1711234567890"
}
```

**Replay logic:** Calls `supabaseService.insertManualList(userId, name)`. The `tempId` is stored for future ID reconciliation (not yet implemented — see Known Limitations).

---

### `renameList`

Triggered when `renameShoppingList()` fails to persist to Supabase.

**Payload structure:**
```json
{
  "listId": "uuid-of-list",
  "newName": "Novo nome da lista"
}
```

**Replay logic:** Calls `supabaseService.updateListName(listId, newName)`.

---

## 6. Error Handling & Retry Logic

### Retry Flow

1. When a Supabase call fails during queue processing, the operation's `retryCount` is incremented via `SyncQueueRepository.updateRetryCount()`.
2. The queue processing stops after the first failure (to avoid cascading failures).
3. On the next connectivity event, `processQueue()` is called again and the operation is retried.
4. After `SyncService.maxRetries = 3` failures, the operation is removed from the queue and `SyncStatusState.error` is emitted with a `lastError` message.

### No Exponential Backoff

The current implementation does not implement exponential backoff. Each retry is attempted immediately when connectivity is restored. This is a known limitation (see Section 9).

### Internal Logging

All Supabase errors are logged internally via `debugPrint()` in the controller:
- `'Erro ao salvar lista no Supabase: $e'`
- `'Erro ao renomear lista no Supabase: $e'`

These messages are never shown to users.

---

## 7. Testing

### Test File: `test/sync_service_test.dart`

**Tests covered:**

| Test | Description |
|------|-------------|
| `Deve enfileir operação quando offline` | Verifies that `enqueue()` persists the operation to `SyncQueueRepository` and increments `pendingCount` |
| `Deve processar fila quando online` | Verifies that `processQueue()` calls Supabase and removes the operation from the queue on success |
| `Deve incrementar retryCount em falha do servidor` | Verifies that a failed Supabase call increments `retryCount` and keeps the operation in the queue |
| `Deve marcar como falha permanente após maxRetries` | Verifies that after `maxRetries` failures, the operation is removed and `status == SyncStatusState.error` |

### Known Limitation: `connectivity_plus` in Unit Tests

The `connectivity_plus` package requires a platform implementation (Android/iOS) that is not available in unit tests. This causes `MissingPluginException` when:
- `SyncService.initialize()` tries to subscribe to `onConnectivityChanged`
- `SyncService.enqueue()` tries to call `checkConnectivity()`
- `SyncService.processQueue()` tries to call `checkConnectivity()`

**Resolution:** The tests call `TestWidgetsFlutterBinding.ensureInitialized()` in `setUp()`. For full test coverage of connectivity-dependent paths, integration tests or a mock `Connectivity` implementation would be needed.

**Workaround for future tests:** The `SyncService` constructor accepts an optional `Connectivity? connectivity` parameter, allowing injection of a mock `Connectivity` instance in tests.

---

## 8. Dependencies Added

| Package | Version | Purpose |
|---------|---------|---------|
| `connectivity_plus` | `^6.0.0` | Monitors network connectivity changes to trigger automatic sync when the device comes back online |

---

## 9. Known Limitations & Future Improvements

### Current Limitations

1. **`createList` ID reconciliation not implemented:** When a `createList` operation is synced, the DB-generated UUID is not propagated back to replace the local `tempId`. The list will have a `tempId` locally and a different UUID in Supabase until the app is restarted and data is reloaded.

2. **No exponential backoff:** Retries happen immediately on the next connectivity event. This could cause rapid retries if the server is temporarily overloaded.

3. **No item-level sync:** Only `createList` and `renameList` operations are queued. Item additions, removals, and updates are not yet covered by the sync queue.

4. **`connectivity_plus` not mockable in unit tests:** The `Connectivity` class is not easily mockable without a custom wrapper, making unit tests for connectivity-dependent paths difficult.

5. **`SyncService` uses `dynamic` for `supabaseService`:** To allow mocking in tests without Supabase initialization, the `_supabaseService` field is typed as `dynamic`. This loses type safety.

### Suggested Future Improvements

1. **Implement ID reconciliation for `createList`:** After successful sync, update the local list's `tempId` to the DB-generated UUID via a callback or event.

2. **Add exponential backoff:** Implement a delay between retries (e.g., 1s, 2s, 4s) to avoid hammering the server.

3. **Extend to item-level operations:** Add `addItem`, `removeItem`, `updateItem` operation types to the sync queue.

4. **Create a `ConnectivityService` wrapper:** Abstract `connectivity_plus` behind an interface to enable proper mocking in unit tests.

5. **Add a sync status indicator in the UI:** Use `context.watch<SyncService>()` to show a badge or banner when `pendingCount > 0` or `status == SyncStatusState.error`.

6. **Use `mockito` for service mocks:** Replace the manual `MockSupabaseListService` class with a generated mock using `mockito` and `build_runner` (already in `dev_dependencies`).
