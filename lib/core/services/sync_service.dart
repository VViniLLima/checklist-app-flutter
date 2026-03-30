import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/shopping_list/models/pending_operation.dart';
import '../../features/shopping_list/data/sync_queue_repository.dart';

/// UUID v4 regex pattern for validation.
final _uuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Returns true if [value] is a valid UUID v4 string.
bool _isValidUuid(String value) => _uuidRegex.hasMatch(value);

/// Service responsible for managing offline-to-online sync of shopping list operations.
///
/// Listens to connectivity changes and processes the pending operations queue
/// sequentially when the device comes back online.
class SyncService extends ChangeNotifier {
  static const int maxRetries = 3;

  final SyncQueueRepository _queueRepo;
  final dynamic _supabaseService; // Use dynamic to allow mocking in tests
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isProcessing = false;

  SyncStatusState _status = SyncStatusState.idle;
  int _pendingCount = 0;
  String? _lastError;

  // Stream for notifying when a createList operation succeeds
  final StreamController<Map<String, String>> _createListSyncController =
      StreamController<Map<String, String>>.broadcast();

  // Stream for notifying when a createCategory operation succeeds
  final StreamController<Map<String, String>> _createCategorySyncController =
      StreamController<Map<String, String>>.broadcast();

  // Stream for notifying when a createItem operation succeeds
  final StreamController<Map<String, String>> _createItemSyncController =
      StreamController<Map<String, String>>.broadcast();

  // Getters for UI
  SyncStatusState get status => _status;
  int get pendingCount => _pendingCount;
  String? get lastError => _lastError;

  /// Stream that emits events when a createList operation is successfully synced.
  /// Each event is a Map with keys 'tempId' and 'dbId'.
  Stream<Map<String, String>> get onCreateListSynced =>
      _createListSyncController.stream;

  /// Stream that emits events when a createCategory operation is successfully synced.
  /// Each event is a Map with keys 'tempId' and 'dbId'.
  Stream<Map<String, String>> get onCreateCategorySynced =>
      _createCategorySyncController.stream;

  /// Stream that emits events when a createItem operation is successfully synced.
  /// Each event is a Map with keys 'tempId' and 'dbId'.
  Stream<Map<String, String>> get onCreateItemSynced =>
      _createItemSyncController.stream;

  SyncService({
    required SyncQueueRepository queueRepo,
    required dynamic supabaseService,
    Connectivity? connectivity,
  }) : _queueRepo = queueRepo,
       _supabaseService = supabaseService,
       _connectivity = connectivity ?? Connectivity();

  /// Initializes the service and starts listening to connectivity changes.
  Future<void> initialize() async {
    await _updatePendingCount();
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  /// Enqueues a new operation for sync.
  Future<void> enqueue(PendingOperation operation) async {
    await _queueRepo.enqueue(operation);
    await _updatePendingCount();
    debugPrint(
      'SyncService: Enqueued operation ${operation.id} (${operation.type})',
    );

    // If we're online, try to process immediately
    final results = await _connectivity.checkConnectivity();
    final isOnline =
        results.isNotEmpty && results.last != ConnectivityResult.none;
    if (isOnline) {
      unawaited(processQueue());
    }
  }

  /// Processes all pending operations in the queue sequentially.
  Future<void> processQueue() async {
    if (_isProcessing) {
      debugPrint('SyncService: Already processing queue, skipping');
      return;
    }

    final results = await _connectivity.checkConnectivity();
    final isOnline =
        results.isNotEmpty && results.last != ConnectivityResult.none;
    if (!isOnline) {
      debugPrint('SyncService: Offline, skipping queue processing');
      return;
    }

    _isProcessing = true;
    _setStatus(SyncStatusState.syncing);
    _lastError = null;

    try {
      final queue = await _queueRepo.loadQueue();
      debugPrint('SyncService: Processing ${queue.length} pending operations');

      for (final operation in queue) {
        try {
          await _processOperation(operation);
          await _queueRepo.remove(operation.id);
          await _updatePendingCount();
          debugPrint(
            'SyncService: Successfully synced operation ${operation.id}',
          );
        } catch (e) {
          debugPrint(
            'SyncService: Failed to sync operation ${operation.id}: $e',
          );

          if (operation.retryCount >= maxRetries) {
            // Max retries reached, mark as permanently failed
            _lastError = 'Falha ao sincronizar: ${operation.type.name}';
            _setStatus(SyncStatusState.error);
            debugPrint(
              'SyncService: Max retries reached for ${operation.id}, marking as failed',
            );
            // Remove from queue so we don't keep retrying
            await _queueRepo.remove(operation.id);
            await _updatePendingCount();
          } else {
            // Increment retry count and re-enqueue
            await _queueRepo.updateRetryCount(
              operation.id,
              operation.retryCount + 1,
            );
            debugPrint(
              'SyncService: Incremented retry count for ${operation.id} to ${operation.retryCount + 1}',
            );
          }
          // Stop processing on first error to avoid cascading failures
          // Reset status to idle since we'll retry on next connectivity event
          _setStatus(SyncStatusState.idle);
          break;
        }
      }

      // If we processed everything without errors, go back to idle
      final remainingQueue = await _queueRepo.loadQueue();
      if (remainingQueue.isEmpty) {
        _setStatus(SyncStatusState.idle);
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Processes a single operation.
  Future<void> _processOperation(PendingOperation operation) async {
    switch (operation.type) {
      case PendingOperationType.createList:
        await _processCreateList(operation);
        break;
      case PendingOperationType.renameList:
        await _processRenameList(operation);
        break;
      case PendingOperationType.deleteList:
        await _processDeleteList(operation);
        break;
      case PendingOperationType.createCategory:
        await _processCreateCategory(operation);
        break;
      case PendingOperationType.updateCategory:
        await _processUpdateCategory(operation);
        break;
      case PendingOperationType.deleteCategory:
        await _processDeleteCategory(operation);
        break;
      case PendingOperationType.createItem:
        await _processCreateItem(operation);
        break;
      case PendingOperationType.updateItem:
        await _processUpdateItem(operation);
        break;
      case PendingOperationType.deleteItem:
        await _processDeleteItem(operation);
        break;
    }
  }

  /// Processes a createList operation.
  Future<void> _processCreateList(PendingOperation operation) async {
    final payload = operation.payload;
    final userId = payload['userId'] as String;
    final name = payload['name'] as String;
    final tempId = payload['tempId'] as String;

    final row = await _supabaseService.insertManualList(
      userId: userId,
      name: name,
    );
    final dbId = row['id'] as String;

    // Notify listeners that a createList operation was successfully synced
    // The controller will use this to update the local list ID from tempId to dbId
    _createListSyncController.add({'tempId': tempId, 'dbId': dbId});
    debugPrint('SyncService: Created list $dbId (was $tempId)');
  }

  /// Processes a renameList operation.
  Future<void> _processRenameList(PendingOperation operation) async {
    final payload = operation.payload;
    final listId = payload['listId'] as String;
    final newName = payload['newName'] as String;

    await _supabaseService.updateListName(listId, newName);
    debugPrint('SyncService: Renamed list $listId to $newName');
  }

  /// Processes a deleteList operation.
  Future<void> _processDeleteList(PendingOperation operation) async {
    final payload = operation.payload;
    final listId = payload['listId'] as String;

    // Skip operations with invalid (non-UUID) list IDs — these were created
    // before UUID generation was introduced and cannot be synced.
    if (!_isValidUuid(listId)) {
      debugPrint(
        'SyncService: Skipping deleteList with invalid listId "$listId" (not a UUID)',
      );
      return;
    }

    await _supabaseService.deleteList(listId);
    debugPrint('SyncService: Deleted list $listId');
  }

  /// Processes a createCategory operation.
  ///
  /// On success, emits an event on [onCreateCategorySynced] so the controller
  /// can replace the local tempId with the DB-generated UUID.
  Future<void> _processCreateCategory(PendingOperation operation) async {
    final payload = operation.payload;
    final listId = payload['listId'] as String;
    final name = payload['name'] as String;
    final corHex = payload['corHex'] as String;
    final ordem = payload['ordem'] as int;
    final tempId = payload['tempId'] as String?;

    // Skip operations with invalid (non-UUID) list IDs — these were created
    // before UUID generation was introduced and cannot be synced.
    if (!_isValidUuid(listId)) {
      debugPrint(
        'SyncService: Skipping createCategory with invalid listId "$listId" (not a UUID)',
      );
      return;
    }

    final row = await _supabaseService.insertCategory(
      listId: listId,
      name: name,
      corHex: corHex,
      ordem: ordem,
    );
    final dbId = row['id'] as String;

    // Notify listeners so the controller can update the local category ID
    if (tempId != null) {
      _createCategorySyncController.add({'tempId': tempId, 'dbId': dbId});
    }
    debugPrint(
      'SyncService: Created category $dbId (was $tempId) in list $listId',
    );
  }

  /// Processes an updateCategory operation.
  Future<void> _processUpdateCategory(PendingOperation operation) async {
    final payload = operation.payload;
    final categoryId = payload['categoryId'] as String;
    final newName = payload['newName'] as String?;
    final newCorHex = payload['newCorHex'] as String?;
    final newColapsada = payload['newColapsada'] as bool?;
    final newOrdem = payload['newOrdem'] as int?;

    // Skip operations with invalid (non-UUID) category IDs — these were created
    // before UUID generation was introduced and cannot be synced.
    if (!_isValidUuid(categoryId)) {
      debugPrint(
        'SyncService: Skipping updateCategory with invalid categoryId "$categoryId" (not a UUID)',
      );
      return;
    }

    if (newCorHex != null) {
      await _supabaseService.updateCategoryColor(categoryId, newCorHex);
    }
    if (newName != null) {
      await _supabaseService.updateCategoryName(categoryId, newName);
    }
    if (newColapsada != null) {
      await _supabaseService.updateCategoryCollapsed(categoryId, newColapsada);
    }
    if (newOrdem != null) {
      await _supabaseService.updateCategoryOrder(categoryId, newOrdem);
    }
    debugPrint('SyncService: Updated category $categoryId');
  }

  /// Processes a deleteCategory operation.
  Future<void> _processDeleteCategory(PendingOperation operation) async {
    final payload = operation.payload;
    final categoryId = payload['categoryId'] as String;

    // Skip operations with invalid (non-UUID) category IDs — these were created
    // before UUID generation was introduced and cannot be synced.
    if (!_isValidUuid(categoryId)) {
      debugPrint(
        'SyncService: Skipping deleteCategory with invalid categoryId "$categoryId" (not a UUID)',
      );
      return;
    }

    await _supabaseService.deleteCategory(categoryId);
    debugPrint('SyncService: Deleted category $categoryId');
  }

  /// Processes a createItem operation.
  ///
  /// On success, emits an event on [onCreateItemSynced] so the controller
  /// can replace the local tempId with the DB-generated UUID.
  Future<void> _processCreateItem(PendingOperation operation) async {
    final payload = operation.payload;
    final listId = payload['listId'] as String;
    final tempId = payload['tempId'] as String?;

    // Skip operations with invalid (non-UUID) list IDs.
    if (!_isValidUuid(listId)) {
      debugPrint(
        'SyncService: Skipping createItem with invalid listId "$listId" (not a UUID)',
      );
      return;
    }

    final categoryId = payload['categoryId'] as String?;
    final nome = payload['nome'] as String;
    final quantidadeCompra = (payload['quantidadeCompra'] as num).toDouble();
    final unidadeCompra = payload['unidadeCompra'] as String;
    final precoCentavos = payload['precoCentavos'] as int;
    final unidadePreco = payload['unidadePreco'] as String;
    final totalCentavos = payload['totalCentavos'] as int;
    final completo = payload['completo'] as bool;
    final origem = payload['origem'] as String;
    final ordem = payload['ordem'] as int;
    final completoEmStr = payload['completoEm'] as String?;
    final completoEm = completoEmStr != null
        ? DateTime.parse(completoEmStr)
        : null;

    final row = await _supabaseService.insertItem(
      listId: listId,
      categoryId: categoryId,
      nome: nome,
      quantidadeCompra: quantidadeCompra,
      unidadeCompra: unidadeCompra,
      precoCentavos: precoCentavos,
      unidadePreco: unidadePreco,
      totalCentavos: totalCentavos,
      completo: completo,
      origem: origem,
      ordem: ordem,
      completoEm: completoEm,
    );
    final dbId = row['id'] as String;

    // Notify listeners so the controller can update the local item ID
    if (tempId != null) {
      _createItemSyncController.add({'tempId': tempId, 'dbId': dbId});
    }
    debugPrint('SyncService: Created item $dbId (was $tempId) in list $listId');
  }

  /// Processes an updateItem operation.
  Future<void> _processUpdateItem(PendingOperation operation) async {
    final payload = operation.payload;
    final itemId = payload['itemId'] as String;

    // Skip operations with invalid (non-UUID) item IDs.
    if (!_isValidUuid(itemId)) {
      debugPrint(
        'SyncService: Skipping updateItem with invalid itemId "$itemId" (not a UUID)',
      );
      return;
    }

    final nome = payload['nome'] as String?;
    final categoryId = payload['categoryId'] as String?;
    final quantidadeCompra = (payload['quantidadeCompra'] as num?)?.toDouble();
    final unidadeCompra = payload['unidadeCompra'] as String?;
    final precoCentavos = payload['precoCentavos'] as int?;
    final unidadePreco = payload['unidadePreco'] as String?;
    final totalCentavos = payload['totalCentavos'] as int?;
    final completo = payload['completo'] as bool?;
    final completoEmStr = payload['completoEm'] as String?;
    final completoEm = completoEmStr != null
        ? DateTime.parse(completoEmStr)
        : null;
    final origem = payload['origem'] as String?;
    final ordem = payload['ordem'] as int?;

    await _supabaseService.updateItem(
      itemId: itemId,
      nome: nome,
      categoryId: categoryId,
      quantidadeCompra: quantidadeCompra,
      unidadeCompra: unidadeCompra,
      precoCentavos: precoCentavos,
      unidadePreco: unidadePreco,
      totalCentavos: totalCentavos,
      completo: completo,
      completoEm: completoEm,
      origem: origem,
      ordem: ordem,
    );
    debugPrint('SyncService: Updated item $itemId');
  }

  /// Processes a deleteItem operation (soft delete via `removido_em`).
  Future<void> _processDeleteItem(PendingOperation operation) async {
    final payload = operation.payload;
    final itemId = payload['itemId'] as String;

    // Skip operations with invalid (non-UUID) item IDs.
    if (!_isValidUuid(itemId)) {
      debugPrint(
        'SyncService: Skipping deleteItem with invalid itemId "$itemId" (not a UUID)',
      );
      return;
    }

    await _supabaseService.softDeleteItem(itemId);
    debugPrint('SyncService: Soft-deleted item $itemId');
  }

  /// Handles connectivity change events.
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.last : ConnectivityResult.none;
    debugPrint('SyncService: Connectivity changed to ${result.name}');
    if (result != ConnectivityResult.none && !_isProcessing) {
      unawaited(processQueue());
    }
  }

  /// Updates the pending count from the repository.
  Future<void> _updatePendingCount() async {
    final queue = await _queueRepo.loadQueue();
    _pendingCount = queue.length;
    notifyListeners();
  }

  /// Updates the sync status and notifies listeners.
  void _setStatus(SyncStatusState newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _createListSyncController.close();
    _createCategorySyncController.close();
    _createItemSyncController.close();
    super.dispose();
  }
}

/// Represents the current sync status.
enum SyncStatusState { idle, syncing, error }
