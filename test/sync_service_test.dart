import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/features/shopping_list/models/pending_operation.dart';
import 'package:checklist_app/features/shopping_list/data/sync_queue_repository.dart';
import 'package:checklist_app/core/services/sync_service.dart';

void main() {
  late SyncQueueRepository queueRepo;
  late SyncService syncService;
  late MockSupabaseListService mockSupabaseService;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    queueRepo = SyncQueueRepository(prefs);
    mockSupabaseService = MockSupabaseListService();
    syncService = SyncService(
      queueRepo: queueRepo,
      supabaseService: mockSupabaseService,
    );
    await syncService.initialize();
  });

  tearDown(() {
    syncService.dispose();
  });

  group('SyncService', () {
    test('Deve enfileir operação quando offline', () async {
      final operation = PendingOperation(
        id: 'op-1',
        type: PendingOperationType.createList,
        payload: {
          'userId': 'user-123',
          'name': 'Test List',
          'tempId': 'temp-1',
        },
        timestamp: DateTime.now(),
      );

      await syncService.enqueue(operation);

      final queue = await queueRepo.loadQueue();
      expect(queue.length, 1);
      expect(queue.first.id, 'op-1');
      expect(syncService.pendingCount, 1);
    });

    test('Deve processar fila quando online', () async {
      // Enqueue an operation
      final operation = PendingOperation(
        id: 'op-2',
        type: PendingOperationType.renameList,
        payload: {'listId': 'list-123', 'newName': 'New Name'},
        timestamp: DateTime.now(),
      );

      await syncService.enqueue(operation);

      // Process queue (simulates coming back online)
      await syncService.processQueue();

      // Verify operation was removed from queue
      final queue = await queueRepo.loadQueue();
      expect(queue.length, 0);
      expect(syncService.pendingCount, 0);

      // Verify Supabase was called
      expect(mockSupabaseService.updateListNameCalled, true);
      expect(mockSupabaseService.lastListId, 'list-123');
      expect(mockSupabaseService.lastNewName, 'New Name');
    });

    test('Deve incrementar retryCount em falha do servidor', () async {
      // Set mock to throw
      mockSupabaseService.shouldThrow = true;

      final operation = PendingOperation(
        id: 'op-3',
        type: PendingOperationType.renameList,
        payload: {'listId': 'list-456', 'newName': 'Retry Name'},
        timestamp: DateTime.now(),
      );

      await syncService.enqueue(operation);

      // Process queue
      await syncService.processQueue();

      // Verify retry count was incremented
      final queue = await queueRepo.loadQueue();
      expect(queue.length, 1);
      expect(queue.first.retryCount, 1);
      expect(syncService.status, SyncStatusState.idle);
    });

    test('Deve marcar como falha permanente após maxRetries', () async {
      // Set mock to throw
      mockSupabaseService.shouldThrow = true;

      final operation = PendingOperation(
        id: 'op-4',
        type: PendingOperationType.renameList,
        payload: {'listId': 'list-789', 'newName': 'Failed Name'},
        timestamp: DateTime.now(),
      );

      // Set retry count to max
      await queueRepo.updateRetryCount('op-4', SyncService.maxRetries);

      // Process queue
      await syncService.processQueue();

      // Verify operation was removed from queue
      final queue = await queueRepo.loadQueue();
      expect(queue.length, 0);
      expect(syncService.status, SyncStatusState.error);
      expect(syncService.lastError, isNotNull);
    });

    test('Deve processar createList operation', () async {
      // Enqueue a createList operation
      final operation = PendingOperation(
        id: 'op-5',
        type: PendingOperationType.createList,
        payload: {
          'userId': 'user-123',
          'name': 'Test List',
          'tempId': 'temp-1',
        },
        timestamp: DateTime.now(),
      );

      await syncService.enqueue(operation);

      // Process queue (simulates coming back online)
      await syncService.processQueue();

      // Verify operation was removed from queue
      final queue = await queueRepo.loadQueue();
      expect(queue.length, 0);
      expect(syncService.pendingCount, 0);

      // Verify Supabase was called
      expect(mockSupabaseService.insertManualListCalled, true);
      expect(mockSupabaseService.lastUserId, 'user-123');
      expect(mockSupabaseService.lastListName, 'Test List');
    });

    test('Deve processar fila imediatamente quando online', () async {
      // Mock connectivity to return online
      // Note: In unit tests, connectivity_plus throws MissingPluginException
      // This test documents the expected behavior when online

      final operation = PendingOperation(
        id: 'op-6',
        type: PendingOperationType.renameList,
        payload: {'listId': 'list-123', 'newName': 'New Name'},
        timestamp: DateTime.now(),
      );

      // Enqueue should trigger immediate processQueue when online
      await syncService.enqueue(operation);

      // Give time for async processing
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify operation was processed
      final queue = await queueRepo.loadQueue();
      expect(queue.length, 0);
    });

    test('Deve resetar status para idle após falha não-permanente', () async {
      // Set mock to throw
      mockSupabaseService.shouldThrow = true;

      final operation = PendingOperation(
        id: 'op-7',
        type: PendingOperationType.renameList,
        payload: {'listId': 'list-456', 'newName': 'Retry Name'},
        timestamp: DateTime.now(),
      );

      await syncService.enqueue(operation);

      // Process queue
      await syncService.processQueue();

      // Verify retry count was incremented
      final queue = await queueRepo.loadQueue();
      expect(queue.length, 1);
      expect(queue.first.retryCount, 1);

      // Verify status was reset to idle (not stuck in syncing)
      expect(syncService.status, SyncStatusState.idle);
    });
  });
}

/// Mock implementation of SupabaseListService for testing
class MockSupabaseListService {
  bool shouldThrow = false;
  bool updateListNameCalled = false;
  bool insertManualListCalled = false;
  String? lastListId;
  String? lastNewName;
  String? lastUserId;
  String? lastListName;
  Map<String, dynamic>? lastInsertedRow;

  MockSupabaseListService();

  Future<void> updateListName(String listId, String newName) async {
    updateListNameCalled = true;
    lastListId = listId;
    lastNewName = newName;
    if (shouldThrow) {
      throw Exception('network error');
    }
  }

  Future<Map<String, dynamic>> insertManualList({
    required String userId,
    required String name,
    String? descricao,
    String moeda = 'BRL',
  }) async {
    insertManualListCalled = true;
    lastUserId = userId;
    lastListName = name;
    if (shouldThrow) {
      throw Exception('network error');
    }
    // Return a mock row with a generated ID
    final row = {
      'id': 'db-generated-${DateTime.now().millisecondsSinceEpoch}',
      'usuario_id': userId,
      'nome': name,
      'descricao': descricao,
      'moeda': moeda,
      'origem': 'manual',
      'status': 'ativa',
    };
    lastInsertedRow = row;
    return row;
  }
}
