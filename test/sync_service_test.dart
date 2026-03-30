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

    group('List Delete Sync Operations', () {
      test('Deve processar deleteList operation', () async {
        // Enqueue a deleteList operation with a valid UUID
        final operation = PendingOperation(
          id: 'op-del-list-1',
          type: PendingOperationType.deleteList,
          payload: {'listId': '550e8400-e29b-41d4-a716-446655440000'},
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);

        // Process queue
        await syncService.processQueue();

        // Verify operation was removed from queue
        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);
        expect(syncService.pendingCount, 0);

        // Verify Supabase was called
        expect(mockSupabaseService.deleteListCalled, true);
        expect(
          mockSupabaseService.lastListId,
          '550e8400-e29b-41d4-a716-446655440000',
        );
      });

      test('Deve pular deleteList com listId inválido', () async {
        // Enqueue a deleteList operation with a non-UUID listId
        final operation = PendingOperation(
          id: 'op-del-list-2',
          type: PendingOperationType.deleteList,
          payload: {'listId': 'list-123'}, // Not a UUID
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);

        // Process queue
        await syncService.processQueue();

        // Verify operation was removed from queue (skipped)
        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);

        // Verify Supabase was NOT called
        expect(mockSupabaseService.deleteListCalled, false);
      });
    });

    group('Category Sync Operations', () {
      test('Deve processar createCategory operation', () async {
        // Enqueue a createCategory operation
        final operation = PendingOperation(
          id: 'op-cat-1',
          type: PendingOperationType.createCategory,
          payload: {
            'listId': 'list-123',
            'name': 'Hortifruti',
            'corHex': '#E3F2FD',
            'ordem': 1,
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
        expect(mockSupabaseService.insertCategoryCalled, true);
        expect(mockSupabaseService.lastInsertedCategoryRow, isNotNull);
        expect(
          mockSupabaseService.lastInsertedCategoryRow?['nome'],
          'Hortifruti',
        );
        expect(
          mockSupabaseService.lastInsertedCategoryRow?['cor_hex'],
          '#E3F2FD',
        );
        expect(mockSupabaseService.lastInsertedCategoryRow?['ordem'], 1);
      });

      test('Deve emitir onCreateCategorySynced com tempId e dbId', () async {
        // Capture events from the stream
        final events = <Map<String, String>>[];
        final sub = syncService.onCreateCategorySynced.listen(events.add);

        // Enqueue a createCategory operation with a valid UUID listId and tempId
        final operation = PendingOperation(
          id: 'op-cat-id-swap',
          type: PendingOperationType.createCategory,
          payload: {
            'listId': '550e8400-e29b-41d4-a716-446655440000',
            'name': 'Laticínios',
            'corHex': '#E3F2FD',
            'ordem': 2,
            'tempId': 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
          },
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);
        await syncService.processQueue();

        // Give the stream a tick to deliver
        await Future.delayed(Duration.zero);

        // Verify the stream emitted the ID swap event
        expect(events.length, 1);
        expect(events.first['tempId'], 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee');
        expect(events.first['dbId'], isNotNull);
        expect(events.first['dbId'], isNotEmpty);

        await sub.cancel();
      });

      test('Deve processar updateCategory operation (nome)', () async {
        // Enqueue an updateCategory operation
        final operation = PendingOperation(
          id: 'op-cat-2',
          type: PendingOperationType.updateCategory,
          payload: {'categoryId': 'cat-123', 'newName': 'Novo nome'},
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);

        // Process queue
        await syncService.processQueue();

        // Verify operation was removed from queue
        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);

        // Verify Supabase was called
        expect(mockSupabaseService.updateCategoryNameCalled, true);
        expect(mockSupabaseService.lastCategoryId, 'cat-123');
        expect(mockSupabaseService.lastCategoryName, 'Novo nome');
      });

      test('Deve processar updateCategory operation (cor)', () async {
        // Enqueue an updateCategory operation
        final operation = PendingOperation(
          id: 'op-cat-3',
          type: PendingOperationType.updateCategory,
          payload: {'categoryId': 'cat-456', 'newCorHex': '#FFCCBC'},
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);

        // Process queue
        await syncService.processQueue();

        // Verify operation was removed from queue
        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);

        // Verify Supabase was called
        expect(mockSupabaseService.updateCategoryColorCalled, true);
        expect(mockSupabaseService.lastCategoryId, 'cat-456');
        expect(mockSupabaseService.lastCategoryCorHex, '#FFCCBC');
      });

      test('Deve processar updateCategory operation (colapsada)', () async {
        // Enqueue an updateCategory operation
        final operation = PendingOperation(
          id: 'op-cat-4',
          type: PendingOperationType.updateCategory,
          payload: {'categoryId': 'cat-789', 'newColapsada': true},
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);

        // Process queue
        await syncService.processQueue();

        // Verify operation was removed from queue
        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);

        // Verify Supabase was called
        expect(mockSupabaseService.updateCategoryCollapsedCalled, true);
        expect(mockSupabaseService.lastCategoryId, 'cat-789');
        expect(mockSupabaseService.lastCategoryColapsada, true);
      });

      test('Deve processar updateCategory operation (ordem)', () async {
        // Enqueue an updateCategory operation
        final operation = PendingOperation(
          id: 'op-cat-5',
          type: PendingOperationType.updateCategory,
          payload: {'categoryId': 'cat-abc', 'newOrdem': 3},
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);

        // Process queue
        await syncService.processQueue();

        // Verify operation was removed from queue
        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);

        // Verify Supabase was called
        expect(mockSupabaseService.updateCategoryOrderCalled, true);
        expect(mockSupabaseService.lastCategoryId, 'cat-abc');
        expect(mockSupabaseService.lastCategoryOrdem, 3);
      });

      test('Deve processar deleteCategory operation', () async {
        // Enqueue a deleteCategory operation
        final operation = PendingOperation(
          id: 'op-cat-6',
          type: PendingOperationType.deleteCategory,
          payload: {'categoryId': 'cat-def'},
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);

        // Process queue
        await syncService.processQueue();

        // Verify operation was removed from queue
        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);

        // Verify Supabase was called
        expect(mockSupabaseService.deleteCategoryCalled, true);
        expect(mockSupabaseService.lastCategoryId, 'cat-def');
      });

      test('Deve pular createCategory com listId inválido', () async {
        // Enqueue a createCategory operation with invalid listId
        final operation = PendingOperation(
          id: 'op-cat-7',
          type: PendingOperationType.createCategory,
          payload: {
            'listId': 'list-123', // Not a UUID
            'name': 'Test',
            'corHex': '#E3F2FD',
            'ordem': 1,
          },
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);

        // Process queue
        await syncService.processQueue();

        // Verify operation was removed from queue (skipped)
        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);

        // Verify Supabase was NOT called
        expect(mockSupabaseService.insertCategoryCalled, false);
      });

      test('Deve pular updateCategory com categoryId inválido', () async {
        // Enqueue an updateCategory operation with invalid categoryId
        final operation = PendingOperation(
          id: 'op-cat-8',
          type: PendingOperationType.updateCategory,
          payload: {
            'categoryId': 'cat-123', // Not a UUID
            'newName': 'Test',
          },
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);

        // Process queue
        await syncService.processQueue();

        // Verify operation was removed from queue (skipped)
        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);

        // Verify Supabase was NOT called
        expect(mockSupabaseService.updateCategoryNameCalled, false);
      });
    });

    group('Item Sync Operations', () {
      test('Deve processar createItem operation', () async {
        final operation = PendingOperation(
          id: 'op-item-1',
          type: PendingOperationType.createItem,
          payload: {
            'listId': '550e8400-e29b-41d4-a716-446655440000',
            'tempId': 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
            'categoryId': null,
            'nome': 'Leite',
            'quantidadeCompra': 2.0,
            'unidadeCompra': 'L',
            'precoCentavos': 450,
            'unidadePreco': 'L',
            'totalCentavos': 900,
            'completo': false,
            'origem': 'manual',
            'ordem': 0,
          },
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);
        await syncService.processQueue();

        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);
        expect(syncService.pendingCount, 0);

        expect(mockSupabaseService.insertItemCalled, true);
        expect(mockSupabaseService.lastInsertedItemRow?['nome'], 'Leite');
        expect(
          mockSupabaseService.lastInsertedItemRow?['preco_base_centavos'],
          450,
        );
        expect(
          mockSupabaseService.lastInsertedItemRow?['valor_total_centavos'],
          900,
        );
      });

      test('Deve emitir onCreateItemSynced com tempId e dbId', () async {
        final events = <Map<String, String>>[];
        final sub = syncService.onCreateItemSynced.listen(events.add);

        final operation = PendingOperation(
          id: 'op-item-id-swap',
          type: PendingOperationType.createItem,
          payload: {
            'listId': '550e8400-e29b-41d4-a716-446655440000',
            'tempId': 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
            'categoryId': null,
            'nome': 'Arroz',
            'quantidadeCompra': 1.0,
            'unidadeCompra': 'kg',
            'precoCentavos': 599,
            'unidadePreco': 'kg',
            'totalCentavos': 599,
            'completo': false,
            'origem': 'manual',
            'ordem': 1,
          },
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);
        await syncService.processQueue();
        await Future.delayed(Duration.zero);

        expect(events.length, 1);
        expect(events.first['tempId'], 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee');
        expect(events.first['dbId'], isNotNull);
        expect(events.first['dbId'], isNotEmpty);

        await sub.cancel();
      });

      test('Deve processar updateItem operation', () async {
        final operation = PendingOperation(
          id: 'op-item-2',
          type: PendingOperationType.updateItem,
          payload: {
            'itemId': '550e8400-e29b-41d4-a716-446655440001',
            'nome': 'Leite integral',
            'precoCentavos': 500,
            'totalCentavos': 1000,
          },
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);
        await syncService.processQueue();

        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);

        expect(mockSupabaseService.updateItemCalled, true);
        expect(
          mockSupabaseService.lastItemId,
          '550e8400-e29b-41d4-a716-446655440001',
        );
      });

      test('Deve processar deleteItem operation (soft delete)', () async {
        final operation = PendingOperation(
          id: 'op-item-3',
          type: PendingOperationType.deleteItem,
          payload: {'itemId': '550e8400-e29b-41d4-a716-446655440002'},
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);
        await syncService.processQueue();

        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);

        expect(mockSupabaseService.softDeleteItemCalled, true);
        expect(
          mockSupabaseService.lastItemId,
          '550e8400-e29b-41d4-a716-446655440002',
        );
      });

      test('Deve pular createItem com listId inválido', () async {
        final operation = PendingOperation(
          id: 'op-item-4',
          type: PendingOperationType.createItem,
          payload: {
            'listId': 'list-123', // Not a UUID
            'tempId': 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
            'categoryId': null,
            'nome': 'Feijão',
            'quantidadeCompra': 1.0,
            'unidadeCompra': 'kg',
            'precoCentavos': 799,
            'unidadePreco': 'kg',
            'totalCentavos': 799,
            'completo': false,
            'origem': 'manual',
            'ordem': 0,
          },
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);
        await syncService.processQueue();

        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);

        expect(mockSupabaseService.insertItemCalled, false);
      });

      test('Deve pular updateItem com itemId inválido', () async {
        final operation = PendingOperation(
          id: 'op-item-5',
          type: PendingOperationType.updateItem,
          payload: {
            'itemId': 'item-123', // Not a UUID
            'nome': 'Teste',
          },
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);
        await syncService.processQueue();

        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);

        expect(mockSupabaseService.updateItemCalled, false);
      });

      test('Deve pular deleteItem com itemId inválido', () async {
        final operation = PendingOperation(
          id: 'op-item-6',
          type: PendingOperationType.deleteItem,
          payload: {'itemId': 'item-456'}, // Not a UUID
          timestamp: DateTime.now(),
        );

        await syncService.enqueue(operation);
        await syncService.processQueue();

        final queue = await queueRepo.loadQueue();
        expect(queue.length, 0);

        expect(mockSupabaseService.softDeleteItemCalled, false);
      });
    });
  });
}

/// Mock implementation of SupabaseListService for testing
class MockSupabaseListService {
  bool shouldThrow = false;
  bool updateListNameCalled = false;
  bool deleteListCalled = false;
  bool insertManualListCalled = false;
  bool insertCategoryCalled = false;
  bool updateCategoryNameCalled = false;
  bool updateCategoryColorCalled = false;
  bool updateCategoryCollapsedCalled = false;
  bool updateCategoryOrderCalled = false;
  bool deleteCategoryCalled = false;
  bool insertItemCalled = false;
  bool updateItemCalled = false;
  bool softDeleteItemCalled = false;
  String? lastListId;
  String? lastNewName;
  String? lastUserId;
  String? lastListName;
  Map<String, dynamic>? lastInsertedRow;
  String? lastCategoryId;
  String? lastCategoryName;
  String? lastCategoryCorHex;
  bool? lastCategoryColapsada;
  int? lastCategoryOrdem;
  Map<String, dynamic>? lastInsertedCategoryRow;
  Map<String, dynamic>? lastInsertedItemRow;
  String? lastItemId;
  Map<String, dynamic>? lastUpdateItemPayload;

  MockSupabaseListService();

  Future<void> updateListName(String listId, String newName) async {
    updateListNameCalled = true;
    lastListId = listId;
    lastNewName = newName;
    if (shouldThrow) {
      throw Exception('network error');
    }
  }

  Future<void> deleteList(String listId) async {
    deleteListCalled = true;
    lastListId = listId;
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

  Future<Map<String, dynamic>> insertCategory({
    required String listId,
    required String name,
    required String corHex,
    required int ordem,
    bool colapsada = false,
  }) async {
    insertCategoryCalled = true;
    if (shouldThrow) {
      throw Exception('network error');
    }
    // Return a mock row with a generated ID
    final row = {
      'id': 'cat-generated-${DateTime.now().millisecondsSinceEpoch}',
      'lista_id': listId,
      'nome': name,
      'cor_hex': corHex,
      'ordem': ordem,
      'colapsada': colapsada,
    };
    lastInsertedCategoryRow = row;
    return row;
  }

  Future<void> updateCategoryName(String categoryId, String newName) async {
    updateCategoryNameCalled = true;
    lastCategoryId = categoryId;
    lastCategoryName = newName;
    if (shouldThrow) {
      throw Exception('network error');
    }
  }

  Future<void> updateCategoryColor(String categoryId, String corHex) async {
    updateCategoryColorCalled = true;
    lastCategoryId = categoryId;
    lastCategoryCorHex = corHex;
    if (shouldThrow) {
      throw Exception('network error');
    }
  }

  Future<void> updateCategoryCollapsed(
    String categoryId,
    bool colapsada,
  ) async {
    updateCategoryCollapsedCalled = true;
    lastCategoryId = categoryId;
    lastCategoryColapsada = colapsada;
    if (shouldThrow) {
      throw Exception('network error');
    }
  }

  Future<void> updateCategoryOrder(String categoryId, int ordem) async {
    updateCategoryOrderCalled = true;
    lastCategoryId = categoryId;
    lastCategoryOrdem = ordem;
    if (shouldThrow) {
      throw Exception('network error');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    deleteCategoryCalled = true;
    lastCategoryId = categoryId;
    if (shouldThrow) {
      throw Exception('network error');
    }
  }

  Future<Map<String, dynamic>> insertItem({
    required String listId,
    required String? categoryId,
    required String nome,
    required double quantidadeCompra,
    required String unidadeCompra,
    required int precoCentavos,
    required String unidadePreco,
    required int totalCentavos,
    required bool completo,
    required String origem,
    required int ordem,
    DateTime? completoEm,
    String? descricao,
    String? refeicaoOrigemResumo,
  }) async {
    insertItemCalled = true;
    if (shouldThrow) {
      throw Exception('network error');
    }
    final row = {
      'id': 'item-generated-${DateTime.now().millisecondsSinceEpoch}',
      'lista_id': listId,
      'categoria_id': categoryId,
      'nome': nome,
      'quantidade_compra': quantidadeCompra,
      'unidade_compra': unidadeCompra,
      'preco_base_centavos': precoCentavos,
      'unidade_preco': unidadePreco,
      'valor_total_centavos': totalCentavos,
      'completo': completo,
      'origem': origem,
      'ordem': ordem,
    };
    lastInsertedItemRow = row;
    return row;
  }

  Future<void> updateItem({
    required String itemId,
    String? nome,
    String? categoryId,
    double? quantidadeCompra,
    String? unidadeCompra,
    int? precoCentavos,
    String? unidadePreco,
    int? totalCentavos,
    bool? completo,
    DateTime? completoEm,
    String? origem,
    int? ordem,
    String? descricao,
  }) async {
    updateItemCalled = true;
    lastItemId = itemId;
    lastUpdateItemPayload = {
      'itemId': itemId,
      if (nome != null) 'nome': nome,
      if (categoryId != null) 'categoryId': categoryId,
      if (quantidadeCompra != null) 'quantidadeCompra': quantidadeCompra,
      if (unidadeCompra != null) 'unidadeCompra': unidadeCompra,
      if (precoCentavos != null) 'precoCentavos': precoCentavos,
      if (unidadePreco != null) 'unidadePreco': unidadePreco,
      if (totalCentavos != null) 'totalCentavos': totalCentavos,
      if (completo != null) 'completo': completo,
      if (completoEm != null) 'completoEm': completoEm.toIso8601String(),
      if (origem != null) 'origem': origem,
      if (ordem != null) 'ordem': ordem,
    };
    if (shouldThrow) {
      throw Exception('network error');
    }
  }

  Future<void> softDeleteItem(String itemId) async {
    softDeleteItemCalled = true;
    lastItemId = itemId;
    if (shouldThrow) {
      throw Exception('network error');
    }
  }
}
