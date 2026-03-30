import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart' as models;
import '../models/shopping_item.dart';
import '../models/shopping_list.dart';
import '../models/pending_operation.dart';
import '../data/shopping_repository.dart';
import '../../../core/services/user_identity_service.dart';
import '../../../core/services/sync_service.dart';
import '../services/supabase_list_service.dart';

const _uuid = Uuid();

/// Result object returned by [addShoppingList].
///
/// Contains the list ID and a flag indicating whether the operation
/// was queued for offline sync (i.e., Supabase failed and the operation
/// will be retried when connectivity is restored).
class AddListResult {
  final String id;
  final bool wasQueuedForSync;

  const AddListResult({required this.id, required this.wasQueuedForSync});
}

/// Result object returned by [addCategory].
///
/// Contains the category ID and a flag indicating whether the operation
/// was queued for offline sync (i.e., Supabase failed and the operation
/// will be retried when connectivity is restored).
class AddCategoryResult {
  final String id;
  final bool wasQueuedForSync;

  const AddCategoryResult({required this.id, required this.wasQueuedForSync});
}

/// Controller principal que gerencia o estado da lista de compras
///
/// Implementa todas as regras de negócio:
/// - Gerenciar múltiplas listas de compras
/// - Adicionar/remover categorias e itens
/// - Marcar/desmarcar itens (com reordenação automática)
/// - Colapsar/expandir categorias
/// - Persistir mudanças automaticamente
/// - Isolar dados por owner (guest ou autenticado)
class ShoppingListController extends ChangeNotifier {
  final ShoppingRepository _repository;
  final UserIdentityService _userIdentityService;

  // Optional Supabase integration — only active for authenticated users
  SupabaseListService? _supabaseListService;
  String? _authenticatedUserId;

  // Optional sync service for offline-to-online sync
  SyncService? _syncService;
  StreamSubscription<Map<String, String>>? _createListSyncSubscription;
  StreamSubscription<Map<String, String>>? _createCategorySyncSubscription;
  StreamSubscription<Map<String, String>>? _createItemSyncSubscription;

  List<ShoppingList> _shoppingLists = [];
  String? _activeListId;
  List<models.Category> _categories = [];
  List<ShoppingItem> _items = [];
  bool _isLoading = true;

  ShoppingListController(this._repository, this._userIdentityService);

  /// Called from [main.dart] whenever auth state changes.
  ///
  /// Pass [null] for both arguments when the user signs out.
  void setSupabaseContext(
    SupabaseListService? service,
    String? authenticatedUserId,
  ) {
    _supabaseListService = service;
    _authenticatedUserId = authenticatedUserId;
  }

  /// Called from [main.dart] to inject the sync service.
  void setSyncService(SyncService? service) {
    // Cancel previous subscriptions if any
    _createListSyncSubscription?.cancel();
    _createCategorySyncSubscription?.cancel();
    _createItemSyncSubscription?.cancel();

    _syncService = service;

    // Subscribe to createList sync events to update local list IDs
    if (service != null) {
      _createListSyncSubscription = service.onCreateListSynced.listen((event) {
        final tempId = event['tempId']!;
        final dbId = event['dbId']!;
        _updateListIdAfterSync(tempId, dbId);
      });

      // Subscribe to createCategory sync events to update local category IDs
      _createCategorySyncSubscription = service.onCreateCategorySynced.listen((
        event,
      ) {
        final tempId = event['tempId']!;
        final dbId = event['dbId']!;
        _updateCategoryIdAfterSync(tempId, dbId);
      });

      // Subscribe to createItem sync events to update local item IDs
      _createItemSyncSubscription = service.onCreateItemSynced.listen((event) {
        final tempId = event['tempId']!;
        final dbId = event['dbId']!;
        _updateItemIdAfterSync(tempId, dbId);
      });
    }
  }

  /// Updates a local list's ID from tempId to dbId after successful sync.
  void _updateListIdAfterSync(String tempId, String dbId) {
    final index = _shoppingLists.indexWhere((list) => list.id == tempId);
    if (index != -1) {
      _shoppingLists[index] = _shoppingLists[index].copyWith(id: dbId);
      // Update active list ID if it was the tempId
      if (_activeListId == tempId) {
        _activeListId = dbId;
      }
      // Persist the updated lists
      _repository.saveShoppingLists(
        _shoppingLists,
        _userIdentityService.currentOwnerId,
      );
      notifyListeners();
      debugPrint(
        'ShoppingListController: Updated list ID from $tempId to $dbId',
      );
    }
  }

  /// Updates a local category's ID from tempId to dbId after successful sync.
  ///
  /// Also updates any items that reference the old tempId so foreign-key
  /// consistency is maintained in local storage.
  void _updateCategoryIdAfterSync(String tempId, String dbId) {
    if (_activeListId == null) return;

    final catIndex = _categories.indexWhere((cat) => cat.id == tempId);
    if (catIndex == -1) return;

    // Replace the category ID
    _categories[catIndex] = _categories[catIndex].copyWith(id: dbId);

    // Update any items that reference the old tempId
    _items = _items.map((item) {
      if (item.categoryId == tempId) {
        return item.copyWith(categoryId: dbId);
      }
      return item;
    }).toList();

    // Persist both
    _repository.saveCategories(_activeListId!, _categories);
    _repository.saveItems(_activeListId!, _items);
    notifyListeners();
    debugPrint(
      'ShoppingListController: Updated category ID from $tempId to $dbId',
    );
  }

  /// Updates a local item's ID from tempId to dbId after successful sync.
  void _updateItemIdAfterSync(String tempId, String dbId) {
    if (_activeListId == null) return;

    final idx = _items.indexWhere((item) => item.id == tempId);
    if (idx == -1) return;

    _items[idx] = _items[idx].copyWith(id: dbId);

    _repository.saveItems(_activeListId!, _items);
    notifyListeners();
    debugPrint('ShoppingListController: Updated item ID from $tempId to $dbId');
  }

  // ==================== Getters ====================

  bool get isLoading => _isLoading;
  List<ShoppingList> get shoppingLists => List.unmodifiable(_shoppingLists);

  List<ShoppingList> get activeLists =>
      _shoppingLists.where((list) => !list.isCompleted).toList();

  List<ShoppingList> get completedLists =>
      _shoppingLists.where((list) => list.isCompleted).toList()..sort(
        (a, b) => (b.purchaseDate ?? b.createdAt).compareTo(
          a.purchaseDate ?? a.createdAt,
        ),
      );

  String? get activeListId => _activeListId;
  ShoppingList? get activeList {
    if (_activeListId == null) return null;
    try {
      return _shoppingLists.firstWhere((list) => list.id == _activeListId);
    } catch (e) {
      return null;
    }
  }

  List<models.Category> get categories =>
      List.unmodifiable(_categories.where((cat) => cat.id != 'sem-categoria'));
  List<ShoppingItem> get allItems => List.unmodifiable(_items);

  int get totalItemsCount => ShoppingItem.getTotalCount(_items);
  int get checkedItemsCount => ShoppingItem.getCompletedCount(_items);
  double get estimatedTotal => _items
      .where((item) => item.totalValue > 0)
      .fold(0.0, (sum, item) => sum + item.totalValue);
  double get cartTotal => _items
      .where((item) => item.isChecked && item.totalValue > 0)
      .fold(0.0, (sum, item) => sum + item.totalValue);
  double get progressRatio =>
      totalItemsCount == 0 ? 0.0 : checkedItemsCount / totalItemsCount;

  /// Retorna itens de uma categoria específica, ordenados conforme regras:
  /// - Itens NÃO marcados primeiro (ordenados por createdAt)
  /// - Itens marcados no final (ordenados por checkedAt)
  List<ShoppingItem> getItemsByCategory(String? categoryId) {
    final searchId = categoryId ?? 'sem-categoria';
    final categoryItems = _items
        .where((item) => (item.categoryId ?? 'sem-categoria') == searchId)
        .toList();

    return _sortItems(categoryItems);
  }

  /// Aplica regras de ordenação:
  /// 1. Itens não marcados primeiro (ordem de criação)
  /// 2. Itens marcados no fim (ordem em que foram marcados)
  List<ShoppingItem> _sortItems(List<ShoppingItem> items) {
    final unchecked = items.where((item) => !item.isChecked).toList();
    final checked = items.where((item) => item.isChecked).toList();

    // Ordena não marcados por data de criação
    unchecked.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Ordena marcados por data em que foram marcados
    checked.sort((a, b) {
      if (a.checkedAt == null && b.checkedAt == null) {
        return a.createdAt.compareTo(b.createdAt);
      }
      if (a.checkedAt == null) return 1;
      if (b.checkedAt == null) return -1;
      return a.checkedAt!.compareTo(b.checkedAt!);
    });

    return [...unchecked, ...checked];
  }

  // ==================== Inicialização ====================

  /// Carrega dados salvos do repositório
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final ownerId = _userIdentityService.currentOwnerId;

      // Migrate ownerless lists first
      await _repository.migrateOwnerlessLists(ownerId);

      // Check if old migration is needed
      if (await _repository.needsMigration()) {
        final migratedList = await _repository.migrateOldData(ownerId);
        if (migratedList != null) {
          _shoppingLists = [migratedList];
          _activeListId = migratedList.id;
        }
      } else {
        _shoppingLists = await _repository.loadShoppingLists(ownerId);
        _activeListId = _repository.loadActiveListId();
      }

      // If no lists exist, create default list
      if (_shoppingLists.isEmpty) {
        final defaultList = ShoppingList(
          id: 'list-1',
          name: 'Lista de compras 1',
          ownerId: ownerId,
          createdAt: DateTime.now(),
          lastModifiedAt: DateTime.now(),
        );
        _shoppingLists = [defaultList];
        _activeListId = defaultList.id;
        await _repository.saveShoppingLists(_shoppingLists, ownerId);
        await _repository.saveActiveListId(_activeListId!);
      }

      // Load data for active list
      if (_activeListId != null) {
        await _loadListData(_activeListId!);
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      _shoppingLists = [];
      _categories = [];
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Recarrega os dados para um novo owner (chamado quando auth state muda)
  Future<void> reloadForOwner() async {
    _isLoading = true;
    notifyListeners();

    try {
      final ownerId = _userIdentityService.currentOwnerId;

      // Migrate ownerless lists first
      await _repository.migrateOwnerlessLists(ownerId);

      // Load lists for the new owner
      _shoppingLists = await _repository.loadShoppingLists(ownerId);

      // Try to keep the active list if it belongs to the new owner
      if (_activeListId != null) {
        final activeListExists = _shoppingLists.any(
          (list) => list.id == _activeListId,
        );
        if (!activeListExists) {
          _activeListId = null;
          _categories = [];
          _items = [];
        }
      }

      // If no active list, set the first one
      if (_activeListId == null && _shoppingLists.isNotEmpty) {
        _activeListId = _shoppingLists.first.id;
        await _repository.saveActiveListId(_activeListId!);
      }

      // Load data for active list
      if (_activeListId != null) {
        await _loadListData(_activeListId!);
      }
    } catch (e) {
      debugPrint('Erro ao recarregar dados: $e');
      _shoppingLists = [];
      _categories = [];
      _items = [];
      _activeListId = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Carrega dados de uma lista específica
  Future<void> _loadListData(String listId) async {
    _categories = await _repository.loadCategories(listId);
    _items = await _repository.loadItems(listId);

    // Ensure "Sem categoria" exists and then normalize sortOrder values
    _ensureSemCategoriaExists();
    await _normalizeCategorySortOrdersIfNeeded();
  }

  /// Normaliza o campo sortOrder das categorias com base na ordem atual
  /// Se detectar valores duplicados ou não-ordenados (ex: dados migrados),
  /// reatribui valores sequenciais (0,1,2...) preservando a ordem atual.
  Future<void> _normalizeCategorySortOrdersIfNeeded() async {
    if (_activeListId == null) return;

    final orders = <int>{};
    var hasDuplicates = false;
    for (final cat in _categories) {
      if (orders.contains(cat.sortOrder)) {
        hasDuplicates = true;
        break;
      }
      orders.add(cat.sortOrder);
    }

    if (!hasDuplicates) return;

    // Re-sequence based on current order
    _categories = List.generate(
      _categories.length,
      (i) => _categories[i].copyWith(sortOrder: i),
    );
    await _repository.saveCategories(_activeListId!, _categories);
  }

  void _ensureSemCategoriaExists() {
    const semCategoriaId = 'sem-categoria';
    final semCategoriaExists = _categories.any(
      (cat) => cat.id == semCategoriaId,
    );
    if (!semCategoriaExists) {
      final semCategoria = models.Category(
        id: semCategoriaId,
        name: 'Sem categoria',
      );
      _categories.insert(0, semCategoria); // Insert at beginning
      if (_activeListId != null) {
        _repository.saveCategories(
          _activeListId!,
          _categories,
        ); // Save immediately
      }
    }
  }

  /// Get the "Sem categoria" category
  models.Category? get semCategoria {
    const semCategoriaId = 'sem-categoria';
    try {
      return _categories.firstWhere((cat) => cat.id == semCategoriaId);
    } catch (e) {
      return null;
    }
  }

  // ==================== Shopping Lists ====================

  /// Adiciona nova lista de compras.
  ///
  /// Inserts locally first (optimistic), then attempts to persist to Supabase
  /// when the user is authenticated. On success, the temporary local ID is
  /// replaced by the DB-generated UUID so local state and the DB stay in sync.
  ///
  /// Returns an [AddListResult] containing the list ID and a flag indicating
  /// whether the operation was queued for offline sync (i.e., Supabase failed).
  Future<AddListResult> addShoppingList(String name) async {
    final ownerId = _userIdentityService.currentOwnerId;
    final tempId = 'list-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final newList = ShoppingList(
      id: tempId,
      name: name,
      ownerId: ownerId,
      createdAt: now,
      lastModifiedAt: now,
    );

    // --- Optimistic local add ---
    _shoppingLists.add(newList);
    await _repository.saveShoppingLists(_shoppingLists, ownerId);
    notifyListeners();

    // --- Supabase persist (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        final row = await _supabaseListService!.insertManualList(
          userId: _authenticatedUserId!,
          name: name,
        );
        final dbId = row['id'] as String;

        // Replace the temporary local ID with the Supabase-generated UUID
        final idx = _shoppingLists.indexWhere((l) => l.id == tempId);
        if (idx != -1) {
          _shoppingLists[idx] = _shoppingLists[idx].copyWith(id: dbId);
          await _repository.saveShoppingLists(_shoppingLists, ownerId);
          notifyListeners();
          return AddListResult(id: dbId, wasQueuedForSync: false);
        }
      } catch (e) {
        debugPrint('Erro ao salvar lista no Supabase: $e');
        // Enqueue for sync instead of rethrowing
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.createList,
            payload: {
              'userId': _authenticatedUserId!,
              'name': name,
              'tempId': tempId,
            },
            timestamp: now,
          );
          await _syncService!.enqueue(operation);
          return AddListResult(id: tempId, wasQueuedForSync: true);
        }
      }
    }

    return AddListResult(id: tempId, wasQueuedForSync: false);
  }

  /// Define a lista ativa e carrega seus dados
  Future<void> setActiveList(String listId) async {
    if (_activeListId == listId) return;

    _activeListId = listId;
    await _repository.saveActiveListId(listId);
    await _loadListData(listId);
    notifyListeners();
  }

  /// Renomeia uma lista de compras existente
  ///
  /// Updates locally first (optimistic), then attempts to persist to Supabase
  /// when the user is authenticated. On success, the name is synced to the DB.
  /// On error, the local name is kept (graceful degradation) and the operation
  /// is enqueued for later sync.
  Future<void> renameShoppingList(String listId, String newName) async {
    final index = _shoppingLists.indexWhere((list) => list.id == listId);
    if (index == -1) return;

    _shoppingLists[index] = _shoppingLists[index].copyWith(
      name: newName,
      lastModifiedAt: DateTime.now(),
    );
    await _repository.saveShoppingLists(
      _shoppingLists,
      _userIdentityService.currentOwnerId,
    );
    notifyListeners();

    // Supabase sync (authenticated users only)
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        await _supabaseListService!.updateListName(listId, newName);
      } catch (e) {
        debugPrint('Erro ao renomear lista no Supabase: $e');
        // Enqueue for sync instead of rethrowing
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.renameList,
            payload: {'listId': listId, 'newName': newName},
            timestamp: DateTime.now(),
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Alterna o estado de favorito de uma lista
  Future<void> toggleFavorite(String listId) async {
    final index = _shoppingLists.indexWhere((list) => list.id == listId);
    if (index == -1) return;

    final current = _shoppingLists[index].isFavorite;
    _shoppingLists[index] = _shoppingLists[index].copyWith(
      isFavorite: !current,
    );
    await _repository.saveShoppingLists(
      _shoppingLists,
      _userIdentityService.currentOwnerId,
    );
    notifyListeners();
  }

  /// Finaliza uma lista e salva no histórico
  ///
  /// Returns true if the operation succeeded, false if it failed.
  /// For authenticated users, this will attempt to persist to Supabase.
  /// If Supabase fails, the local state is still updated but the method returns false.
  Future<bool> finalizeList(
    String listId, {
    required String location,
    required DateTime date,
    required double totalSpent,
  }) async {
    final index = _shoppingLists.indexWhere((list) => list.id == listId);
    if (index == -1) return false;

    // --- Optimistic local update ---
    _shoppingLists[index] = _shoppingLists[index].copyWith(
      isCompleted: true,
      purchaseLocation: location,
      purchaseDate: date,
      totalSpent: totalSpent,
      lastModifiedAt: DateTime.now(),
    );

    await _repository.saveShoppingLists(
      _shoppingLists,
      _userIdentityService.currentOwnerId,
    );
    notifyListeners();

    // --- Supabase persist (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        // Convert totalSpent from double to cents
        final valorTotalCentavos = (totalSpent * 100).round();

        await _supabaseListService!.finalizeList(
          listId: listId,
          ownerUsuarioId: _authenticatedUserId!,
          finalizadoPorUsuarioId: _authenticatedUserId!,
          localCompra: location,
          dataCompra: date,
          valorTotalCentavos: valorTotalCentavos,
        );
        return true;
      } catch (e) {
        debugPrint('Erro ao finalizar lista no Supabase: $e');
        // Return false to indicate Supabase sync failed
        // Note: We don't enqueue for sync because finalization is a one-time operation
        // that should be atomic. If it fails, the user should retry manually.
        return false;
      }
    }

    return true;
  }

  /// Exclui uma lista de compras e todos os seus dados
  ///
  /// Removes locally first (optimistic), then attempts to persist to Supabase
  /// when the user is authenticated. On error, the operation is enqueued for
  /// later sync.
  Future<void> deleteShoppingList(String listId) async {
    // --- Optimistic local delete ---
    _shoppingLists.removeWhere((list) => list.id == listId);

    // Remove os dados associados (categorias e itens)
    await _repository.deleteListData(listId);

    // Salva a lista atualizada de listas
    await _repository.saveShoppingLists(
      _shoppingLists,
      _userIdentityService.currentOwnerId,
    );

    // Se a lista excluída era a ativa, muda para outra
    if (_activeListId == listId) {
      _activeListId = _shoppingLists.isNotEmpty
          ? _shoppingLists.first.id
          : null;
      if (_activeListId != null) {
        await _loadListData(_activeListId!);
      } else {
        _categories = [];
        _items = [];
      }
    }

    notifyListeners();

    // --- Supabase persist (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        await _supabaseListService!.deleteList(listId);
      } catch (e) {
        debugPrint('Erro ao excluir lista no Supabase: $e');
        // Enqueue for sync instead of rethrowing
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.deleteList,
            payload: {'listId': listId},
            timestamp: DateTime.now(),
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Duplica uma lista de compras com todas as suas categorias e itens
  Future<void> duplicateShoppingList(String listId) async {
    final original = _shoppingLists.firstWhere((list) => list.id == listId);

    // Cria nova lista com nome modificado
    final newId = 'list-${DateTime.now().millisecondsSinceEpoch}';
    final newList = ShoppingList(
      id: newId,
      name: '${original.name} (cópia)',
      ownerId: _userIdentityService.currentOwnerId,
      createdAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
    );

    // Copia categorias e itens da lista original
    final categories = await _repository.loadCategories(listId);
    final items = await _repository.loadItems(listId);

    // Salva os dados da nova lista
    await _repository.saveCategories(newId, categories);
    await _repository.saveItems(newId, items);

    // Adiciona a nova lista à lista de listas
    _shoppingLists.add(newList);
    await _repository.saveShoppingLists(
      _shoppingLists,
      _userIdentityService.currentOwnerId,
    );

    notifyListeners();
  }

  /// Recupera dados de uma lista específica (para histórico) sem torná-la ativa
  Future<Map<String, dynamic>> getHistoryListData(String listId) async {
    final categories = await _repository.loadCategories(listId);
    final items = await _repository.loadItems(listId);
    return {'categories': categories, 'items': items};
  }

  // ==================== Categorias ====================

  /// Adiciona nova categoria
  ///
  /// Returns an [AddCategoryResult] containing the category ID and a flag indicating
  /// whether the operation was queued for offline sync (i.e., Supabase failed).
  Future<AddCategoryResult> addCategory(String name) async {
    if (_activeListId == null) {
      return const AddCategoryResult(id: '', wasQueuedForSync: false);
    }

    final tempId = _uuid.v4();
    final now = DateTime.now();
    final corHex = '#E3F2FD'; // Default color

    final newCategory = models.Category.create(
      id: tempId,
      name: name,
      // Assign next sort order at the end of current categories
      sortOrder: (_categories.isEmpty
          ? 0
          : _categories
                    .map((c) => c.sortOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1),
      corHex: corHex,
    );

    // --- Optimistic local add ---
    _categories.add(newCategory);
    await _updateActiveListTimestamp();
    await _repository.saveCategories(_activeListId!, _categories);
    notifyListeners();

    // --- Supabase persist (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        final row = await _supabaseListService!.insertCategory(
          listId: _activeListId!,
          name: name,
          corHex: corHex,
          ordem: newCategory.sortOrder,
        );
        final dbId = row['id'] as String;

        // Replace the temporary local ID with the Supabase-generated UUID
        final idx = _categories.indexWhere((c) => c.id == tempId);
        if (idx != -1) {
          _categories[idx] = _categories[idx].copyWith(id: dbId);
          // Update any items that already reference the tempId
          _items = _items.map((item) {
            if (item.categoryId == tempId) {
              return item.copyWith(categoryId: dbId);
            }
            return item;
          }).toList();
          await _repository.saveCategories(_activeListId!, _categories);
          await _repository.saveItems(_activeListId!, _items);
          notifyListeners();
        }
        return AddCategoryResult(id: dbId, wasQueuedForSync: false);
      } catch (e) {
        debugPrint('Erro ao salvar categoria no Supabase: $e');
        // Enqueue for sync instead of rethrowing
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.createCategory,
            payload: {
              'listId': _activeListId!,
              'name': name,
              'corHex': corHex,
              'ordem': newCategory.sortOrder,
              'tempId': tempId, // needed so SyncService can emit the ID swap
            },
            timestamp: now,
          );
          await _syncService!.enqueue(operation);
          return AddCategoryResult(id: tempId, wasQueuedForSync: true);
        }
      }
    }

    return AddCategoryResult(id: tempId, wasQueuedForSync: false);
  }

  /// Remove categoria (itens ficam sem categoria)
  Future<void> removeCategory(String categoryId) async {
    if (_activeListId == null) return;
    if (categoryId == 'sem-categoria') return;

    // --- Optimistic local remove ---
    _categories.removeWhere((cat) => cat.id == categoryId);

    // Move itens da categoria removida para "Sem categoria"
    _items = _items.map((item) {
      if (item.categoryId == categoryId) {
        return item.copyWith(categoryId: 'sem-categoria');
      }
      return item;
    }).toList();

    await _updateActiveListTimestamp();
    await _repository.saveCategories(_activeListId!, _categories);
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();

    // --- Supabase persist (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        await _supabaseListService!.deleteCategory(categoryId);
      } catch (e) {
        debugPrint('Erro ao remover categoria no Supabase: $e');
        // Enqueue for sync instead of rethrowing
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.deleteCategory,
            payload: {'categoryId': categoryId},
            timestamp: DateTime.now(),
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Exclui uma categoria e todos os seus itens
  Future<void> deleteCategory(String categoryId) async {
    if (_activeListId == null) return;
    if (categoryId == 'sem-categoria') return;

    // --- Optimistic local delete ---
    _categories.removeWhere((cat) => cat.id == categoryId);
    _items.removeWhere((item) => item.categoryId == categoryId);

    await _updateActiveListTimestamp();
    await _repository.saveCategories(_activeListId!, _categories);
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();

    // --- Supabase persist (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        await _supabaseListService!.deleteCategory(categoryId);
      } catch (e) {
        debugPrint('Erro ao excluir categoria no Supabase: $e');
        // Enqueue for sync instead of rethrowing
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.deleteCategory,
            payload: {'categoryId': categoryId},
            timestamp: DateTime.now(),
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Edita o nome de uma categoria existente
  Future<void> editCategory(String categoryId, String newName) async {
    if (_activeListId == null) return;

    // --- Optimistic local update ---
    _categories = _categories.map((cat) {
      if (cat.id == categoryId) {
        return cat.copyWith(name: newName);
      }
      return cat;
    }).toList();

    await _updateActiveListTimestamp();
    await _repository.saveCategories(_activeListId!, _categories);
    notifyListeners();

    // --- Supabase persist (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        await _supabaseListService!.updateCategoryName(categoryId, newName);
      } catch (e) {
        debugPrint('Erro ao atualizar categoria no Supabase: $e');
        // Enqueue for sync instead of rethrowing
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.updateCategory,
            payload: {'categoryId': categoryId, 'newName': newName},
            timestamp: DateTime.now(),
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Edita a cor de uma categoria existente
  Future<void> editCategoryColor(String categoryId, int colorValue) async {
    if (_activeListId == null) return;

    // --- Optimistic local update ---
    _categories = _categories.map((cat) {
      if (cat.id == categoryId) {
        return cat.copyWith(colorValue: colorValue);
      }
      return cat;
    }).toList();

    await _updateActiveListTimestamp();
    await _repository.saveCategories(_activeListId!, _categories);
    notifyListeners();

    // --- Supabase persist (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        // Convert int colorValue to hex string
        final corHex =
            '#${colorValue.toRadixString(16).padLeft(8, '0').toUpperCase()}';
        await _supabaseListService!.updateCategoryColor(categoryId, corHex);
      } catch (e) {
        debugPrint('Erro ao atualizar cor da categoria no Supabase: $e');
        // Enqueue for sync instead of rethrowing
        if (_syncService != null) {
          final corHex =
              '#${colorValue.toRadixString(16).padLeft(8, '0').toUpperCase()}';
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.updateCategory,
            payload: {'categoryId': categoryId, 'newCorHex': corHex},
            timestamp: DateTime.now(),
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Alterna estado de colapso de uma categoria
  Future<void> toggleCategoryCollapse(String categoryId) async {
    if (_activeListId == null) return;

    // --- Optimistic local update ---
    final category = _categories.firstWhere((cat) => cat.id == categoryId);
    final newCollapsedState = !category.isCollapsed;

    _categories = _categories.map((cat) {
      if (cat.id == categoryId) {
        return cat.copyWith(isCollapsed: newCollapsedState);
      }
      return cat;
    }).toList();

    await _updateActiveListTimestamp();
    await _repository.saveCategories(_activeListId!, _categories);
    notifyListeners();

    // --- Supabase sync (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        await _supabaseListService!.updateCategoryCollapsed(
          categoryId,
          newCollapsedState,
        );
      } catch (e) {
        debugPrint('Erro ao atualizar colapso da categoria no Supabase: $e');
        // Enqueue for sync instead of rethrowing
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.updateCategory,
            payload: {
              'categoryId': categoryId,
              'newColapsada': newCollapsedState,
            },
            timestamp: DateTime.now(),
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Reordena categorias mantendo "Sem categoria" fora da lista reordenavel
  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (_activeListId == null) return;
    if (oldIndex == newIndex) return;
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Reorder only within the active (not-completed) group
    final reorderableCategories = _categories
        .where((cat) => cat.id != 'sem-categoria')
        .toList();

    // Disallow moving a category that is already completed
    final movedCategory = reorderableCategories[oldIndex];
    if (isCategoryCompleted(movedCategory.id)) return;

    // Build active and completed groups preserving relative order
    final activeCats = <models.Category>[];
    final completedCats = <models.Category>[];
    for (final c in reorderableCategories) {
      if (isCategoryCompleted(c.id)) {
        completedCats.add(c);
      } else {
        activeCats.add(c);
      }
    }

    // Compute positions within activeCats based on original indexes
    final activeOldIndex = activeCats.indexWhere(
      (c) => c.id == movedCategory.id,
    );
    if (activeOldIndex == -1) return; // safety

    // Convert newIndex (index in reorderableCategories) to index within activeCats
    var activeNewIndex = 0;
    for (var i = 0; i < newIndex; i++) {
      if (!isCategoryCompleted(reorderableCategories[i].id)) activeNewIndex++;
    }

    // Remove and insert within active list
    activeCats.removeAt(activeOldIndex);
    // Clamp insertion index
    if (activeNewIndex < 0) activeNewIndex = 0;
    if (activeNewIndex > activeCats.length) activeNewIndex = activeCats.length;
    activeCats.insert(activeNewIndex, movedCategory);

    // Rebuild full categories list with sem-categoria first
    final semCategoria = _categories.firstWhere(
      (cat) => cat.id == 'sem-categoria',
    );
    _categories = [semCategoria, ...activeCats, ...completedCats];

    // Update sortOrder to reflect new persisted order (preserve sem-categoria at 0)
    for (var i = 0; i < _categories.length; i++) {
      _categories[i] = _categories[i].copyWith(sortOrder: i);
    }

    await _updateActiveListTimestamp();
    await _repository.saveCategories(_activeListId!, _categories);
    notifyListeners();

    // --- Supabase sync (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        // Sync ordem for all categories (except sem-categoria which is local-only)
        for (final cat in _categories) {
          if (cat.id != 'sem-categoria') {
            await _supabaseListService!.updateCategoryOrder(
              cat.id,
              cat.sortOrder,
            );
          }
        }
      } catch (e) {
        debugPrint('Erro ao atualizar ordem das categorias no Supabase: $e');
        // Enqueue for sync instead of rethrowing
        if (_syncService != null) {
          // Queue updateCategory operations for each category with new ordem
          for (final cat in _categories) {
            if (cat.id != 'sem-categoria') {
              final operation = PendingOperation(
                id: 'op-${DateTime.now().millisecondsSinceEpoch}-${cat.id}',
                type: PendingOperationType.updateCategory,
                payload: {'categoryId': cat.id, 'newOrdem': cat.sortOrder},
                timestamp: DateTime.now(),
              );
              await _syncService!.enqueue(operation);
            }
          }
        }
      }
    }
  }

  // ==================== Itens ====================

  /// Converts a double currency value to integer cents (e.g. 2.50 → 250).
  static int _toCents(double value) => (value * 100).round();

  /// Builds the payload map for a [PendingOperationType.createItem] operation.
  Map<String, dynamic> _buildCreateItemPayload(ShoppingItem item) {
    return {
      'listId': item.listId ?? _activeListId!,
      'tempId': item.id,
      'categoryId': item.categoryId == 'sem-categoria' ? null : item.categoryId,
      'nome': item.name,
      'quantidadeCompra': item.quantityValue,
      'unidadeCompra': item.quantityUnit,
      'precoCentavos': _toCents(item.priceValue),
      'unidadePreco': item.priceUnit,
      'totalCentavos': _toCents(item.totalValue),
      'completo': item.isChecked,
      'completoEm': item.checkedAt?.toUtc().toIso8601String(),
      'origem': item.origem.name,
      'ordem': item.ordemDb,
    };
  }

  /// Adds a new item to a category (or to 'sem-categoria' when categoryId is null).
  ///
  /// Inserts locally first (optimistic), then attempts to persist to Supabase.
  /// On success, the temporary local ID is replaced by the DB-generated UUID.
  /// On failure, the operation is enqueued for later sync.
  Future<void> addItem(
    String name,
    String? categoryId, {
    double? quantityValue,
    String? quantityUnit,
    double? priceValue,
    String? priceUnit,
    double? totalValue,
    ItemOrigem origem = ItemOrigem.manual,
  }) async {
    if (_activeListId == null) return;

    final tempId = _uuid.v4();
    final now = DateTime.now();

    final newItem = ShoppingItem.create(
      id: tempId,
      name: name,
      categoryId: categoryId ?? 'sem-categoria',
      listId: _activeListId,
      quantityValue: quantityValue ?? 0.0,
      quantityUnit: quantityUnit ?? 'und',
      priceValue: priceValue ?? 0.0,
      priceUnit: priceUnit ?? 'und',
      totalValue: totalValue ?? 0.0,
      origem: origem,
      ordemDb: _items.length,
    );

    // --- Optimistic local add ---
    _items.add(newItem);
    await _updateActiveListTimestamp();
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();

    // Re-evaluate category ordering because adding an item can change completion
    await reorderCategoriesBasedOnCompletion();

    // --- Supabase persist (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        final row = await _supabaseListService!.insertItem(
          listId: _activeListId!,
          categoryId: newItem.categoryId == 'sem-categoria'
              ? null
              : newItem.categoryId,
          nome: name,
          quantidadeCompra: newItem.quantityValue,
          unidadeCompra: newItem.quantityUnit,
          precoCentavos: _toCents(newItem.priceValue),
          unidadePreco: newItem.priceUnit,
          totalCentavos: _toCents(newItem.totalValue),
          completo: newItem.isChecked,
          origem: newItem.origem.name,
          ordem: newItem.ordemDb,
        );
        final dbId = row['id'] as String;

        // Replace the temporary local ID with the Supabase-generated UUID
        final idx = _items.indexWhere((i) => i.id == tempId);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(id: dbId);
          await _repository.saveItems(_activeListId!, _items);
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Erro ao salvar item no Supabase: $e');
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.createItem,
            payload: _buildCreateItemPayload(newItem),
            timestamp: now,
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Removes an item from the list (soft-deletes in Supabase).
  ///
  /// Removes locally first (optimistic), then attempts to soft-delete in Supabase.
  /// On failure, the operation is enqueued for later sync.
  Future<void> removeItem(String itemId) async {
    if (_activeListId == null) return;

    _items.removeWhere((item) => item.id == itemId);
    await _updateActiveListTimestamp();
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();

    // Re-evaluate categories since removing an item may change completion state
    await reorderCategoriesBasedOnCompletion();

    // --- Supabase persist (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        await _supabaseListService!.softDeleteItem(itemId);
      } catch (e) {
        debugPrint('Erro ao remover item no Supabase: $e');
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.deleteItem,
            payload: {'itemId': itemId},
            timestamp: DateTime.now(),
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Edits an existing item with the provided fields.
  ///
  /// Updates locally first (optimistic), then attempts to persist to Supabase.
  /// If the item was LLM-generated, its [origem] is promoted to [ItemOrigem.ajuste].
  /// On failure, the operation is enqueued for later sync.
  Future<void> editItem(
    String itemId, {
    String? name,
    double? quantityValue,
    String? quantityUnit,
    double? priceValue,
    String? priceUnit,
    double? totalValue,
  }) async {
    if (_activeListId == null) return;

    ShoppingItem? updatedItem;
    _items = _items.map((item) {
      if (item.id == itemId) {
        // Promote origem from llm → ajuste when the user edits an LLM item
        final newOrigem = item.origem == ItemOrigem.llm
            ? ItemOrigem.ajuste
            : item.origem;
        final updated = item.copyWith(
          name: name,
          quantityValue: quantityValue,
          quantityUnit: quantityUnit,
          priceValue: priceValue,
          priceUnit: priceUnit,
          totalValue: totalValue,
          origem: newOrigem,
          atualizadoEm: DateTime.now(),
        );
        updatedItem = updated;
        return updated;
      }
      return item;
    }).toList();

    await _updateActiveListTimestamp();
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();

    await reorderCategoriesBasedOnCompletion();

    // --- Supabase persist (authenticated users only) ---
    if (updatedItem != null &&
        _supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        await _supabaseListService!.updateItem(
          itemId: itemId,
          nome: name,
          quantidadeCompra: quantityValue,
          unidadeCompra: quantityUnit,
          precoCentavos: priceValue != null ? _toCents(priceValue) : null,
          unidadePreco: priceUnit,
          totalCentavos: totalValue != null ? _toCents(totalValue) : null,
          origem: updatedItem!.origem.name,
        );
      } catch (e) {
        debugPrint('Erro ao editar item no Supabase: $e');
        if (_syncService != null) {
          final payload = <String, dynamic>{'itemId': itemId};
          if (name != null) payload['nome'] = name;
          if (quantityValue != null)
            payload['quantidadeCompra'] = quantityValue;
          if (quantityUnit != null) payload['unidadeCompra'] = quantityUnit;
          if (priceValue != null) {
            payload['precoCentavos'] = _toCents(priceValue);
          }
          if (priceUnit != null) payload['unidadePreco'] = priceUnit;
          if (totalValue != null) {
            payload['totalCentavos'] = _toCents(totalValue);
          }
          payload['origem'] = updatedItem!.origem.name;
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.updateItem,
            payload: payload,
            timestamp: DateTime.now(),
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Marks/unmarks an item as checked.
  ///
  /// When checked:
  /// - Sets checkedAt for ordering
  /// - Item is automatically moved to the end via sorting
  ///
  /// When unchecked:
  /// - Clears checkedAt
  /// - Item returns to the top (among unchecked items)
  Future<void> toggleItemCheck(String itemId) async {
    if (_activeListId == null) return;

    ShoppingItem? updatedItem;
    _items = _items.map((item) {
      if (item.id == itemId) {
        final newCheckedState = !item.isChecked;
        final updated = item.copyWith(
          isChecked: newCheckedState,
          checkedAt: newCheckedState ? DateTime.now() : null,
          atualizadoEm: DateTime.now(),
        );
        updatedItem = updated;
        return updated;
      }
      return item;
    }).toList();

    await _updateActiveListTimestamp();
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();

    // Re-evaluate ordering - toggling can change category completion
    await reorderCategoriesBasedOnCompletion();

    // --- Supabase persist (authenticated users only) ---
    if (updatedItem != null &&
        _supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        await _supabaseListService!.updateItem(
          itemId: itemId,
          completo: updatedItem!.isChecked,
          completoEm: updatedItem!.checkedAt,
        );
      } catch (e) {
        debugPrint('Erro ao atualizar estado do item no Supabase: $e');
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.updateItem,
            payload: {
              'itemId': itemId,
              'completo': updatedItem!.isChecked,
              'completoEm': updatedItem!.checkedAt?.toUtc().toIso8601String(),
            },
            timestamp: DateTime.now(),
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Marks an item as checked (no-op if already checked).
  Future<void> markItemChecked(String itemId) async {
    if (_activeListId == null) return;

    ShoppingItem? updatedItem;
    var didUpdate = false;
    _items = _items.map((item) {
      if (item.id == itemId) {
        if (item.isChecked) return item;
        didUpdate = true;
        final updated = item.copyWith(
          isChecked: true,
          checkedAt: DateTime.now(),
          atualizadoEm: DateTime.now(),
        );
        updatedItem = updated;
        return updated;
      }
      return item;
    }).toList();

    if (!didUpdate) return;
    await _updateActiveListTimestamp();
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();

    // Re-evaluate ordering after marking
    await reorderCategoriesBasedOnCompletion();

    // --- Supabase persist (authenticated users only) ---
    if (updatedItem != null &&
        _supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        await _supabaseListService!.updateItem(
          itemId: itemId,
          completo: true,
          completoEm: updatedItem!.checkedAt,
        );
      } catch (e) {
        debugPrint('Erro ao marcar item no Supabase: $e');
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.updateItem,
            payload: {
              'itemId': itemId,
              'completo': true,
              'completoEm': updatedItem!.checkedAt?.toUtc().toIso8601String(),
            },
            timestamp: DateTime.now(),
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Restores a removed item (used by Undo).
  ///
  /// Re-inserts locally and re-creates in Supabase (since the item was
  /// soft-deleted, we insert a fresh row with the same data).
  Future<void> restoreItem(ShoppingItem item) async {
    if (_activeListId == null) return;

    _items.removeWhere((existing) => existing.id == item.id);
    _items.add(item);
    await _updateActiveListTimestamp();
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();

    // Restoring an item can change completion state
    await reorderCategoriesBasedOnCompletion();

    // --- Supabase persist (authenticated users only) ---
    // Re-insert the item (the previous soft-delete may have already been synced)
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        final row = await _supabaseListService!.insertItem(
          listId: item.listId ?? _activeListId!,
          categoryId: item.categoryId == 'sem-categoria'
              ? null
              : item.categoryId,
          nome: item.name,
          quantidadeCompra: item.quantityValue,
          unidadeCompra: item.quantityUnit,
          precoCentavos: _toCents(item.priceValue),
          unidadePreco: item.priceUnit,
          totalCentavos: _toCents(item.totalValue),
          completo: item.isChecked,
          completoEm: item.checkedAt,
          origem: item.origem.name,
          ordem: item.ordemDb,
        );
        final dbId = row['id'] as String;
        final idx = _items.indexWhere((i) => i.id == item.id);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(id: dbId);
          await _repository.saveItems(_activeListId!, _items);
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Erro ao restaurar item no Supabase: $e');
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.createItem,
            payload: _buildCreateItemPayload(item),
            timestamp: DateTime.now(),
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Moves an existing item to another category (or to 'sem-categoria' when null).
  Future<void> moveItemToCategory(String itemId, String? newCategoryId) async {
    if (_activeListId == null) return;

    final existingIndex = _items.indexWhere((i) => i.id == itemId);
    if (existingIndex == -1) return;

    final existing = _items[existingIndex];
    if (existing.categoryId == newCategoryId) return; // no-op

    _items = _items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          categoryId: newCategoryId,
          atualizadoEm: DateTime.now(),
        );
      }
      return item;
    }).toList();

    await _updateActiveListTimestamp();
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();

    // Re-evaluate categories since source/destination completion may change
    await reorderCategoriesBasedOnCompletion();

    // --- Supabase persist (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      final dbCategoryId = newCategoryId == 'sem-categoria'
          ? null
          : newCategoryId;
      try {
        await _supabaseListService!.updateItem(
          itemId: itemId,
          categoryId: dbCategoryId,
        );
      } catch (e) {
        debugPrint('Erro ao mover item no Supabase: $e');
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.updateItem,
            payload: {'itemId': itemId, 'categoryId': dbCategoryId},
            timestamp: DateTime.now(),
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  /// Copies an existing item into another category (creates a new item).
  ///
  /// The copied item will be unchecked by default and have a new id/createdAt.
  Future<void> copyItemToCategory(
    String itemId,
    String? destinationCategoryId,
  ) async {
    if (_activeListId == null) return;

    final originalIndex = _items.indexWhere((i) => i.id == itemId);
    if (originalIndex == -1) return;
    final original = _items[originalIndex];

    final tempId = _uuid.v4();
    final now = DateTime.now();

    final newItem = ShoppingItem.create(
      id: tempId,
      name: original.name,
      quantityValue: original.quantityValue,
      quantityUnit: original.quantityUnit,
      priceValue: original.priceValue,
      priceUnit: original.priceUnit,
      totalValue: original.totalValue,
      categoryId: destinationCategoryId,
      listId: _activeListId,
      isChecked: false,
      origem: ItemOrigem.manual,
      ordemDb: _items.length,
    );

    // --- Optimistic local add ---
    _items.add(newItem);
    await _updateActiveListTimestamp();
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();

    // Re-evaluate categories since destination completion may change
    await reorderCategoriesBasedOnCompletion();

    // --- Supabase persist (authenticated users only) ---
    if (_supabaseListService != null &&
        _authenticatedUserId != null &&
        _authenticatedUserId!.isNotEmpty) {
      try {
        final row = await _supabaseListService!.insertItem(
          listId: _activeListId!,
          categoryId: newItem.categoryId == 'sem-categoria'
              ? null
              : newItem.categoryId,
          nome: newItem.name,
          quantidadeCompra: newItem.quantityValue,
          unidadeCompra: newItem.quantityUnit,
          precoCentavos: _toCents(newItem.priceValue),
          unidadePreco: newItem.priceUnit,
          totalCentavos: _toCents(newItem.totalValue),
          completo: false,
          origem: newItem.origem.name,
          ordem: newItem.ordemDb,
        );
        final dbId = row['id'] as String;

        final idx = _items.indexWhere((i) => i.id == tempId);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(id: dbId);
          await _repository.saveItems(_activeListId!, _items);
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Erro ao copiar item no Supabase: $e');
        if (_syncService != null) {
          final operation = PendingOperation(
            id: 'op-${DateTime.now().millisecondsSinceEpoch}',
            type: PendingOperationType.createItem,
            payload: _buildCreateItemPayload(newItem),
            timestamp: now,
          );
          await _syncService!.enqueue(operation);
        }
      }
    }
  }

  // ==================== Utilidades ====================

  /// Verifica se uma categoria está colapsada
  bool isCategoryCollapsed(String? categoryId) {
    final searchId = categoryId ?? 'sem-categoria';
    final category = _categories.firstWhere(
      (cat) => cat.id == searchId,
      orElse: () => models.Category(id: '', name: '', isCollapsed: false),
    );
    return category.isCollapsed;
  }

  /// Retorna true se a categoria for considerada COMPLETA:
  /// - Não é a categoria especial 'sem-categoria'
  /// - Possui ao menos 1 item
  /// - Todos os seus itens possuem isChecked == true
  bool isCategoryCompleted(String? categoryId) {
    if (categoryId == null) return false;
    if (categoryId == 'sem-categoria') return false;

    final categoryItems = _items
        .where((i) => i.categoryId == categoryId)
        .toList();
    if (categoryItems.isEmpty) {
      return false; // Empty categories are NOT completed
    }

    return categoryItems.every((i) => i.isChecked);
  }

  /// Reorders categories so that completed categories move to the end
  /// - Preserves manual order among active (not completed) categories
  /// - Preserves relative order among completed categories (stable)
  /// - Does nothing during initial loading
  Future<void> reorderCategoriesBasedOnCompletion() async {
    if (_isLoading) return; // do not reorder while loading
    if (_activeListId == null) return;

    final sem = _categories.firstWhere(
      (c) => c.id == 'sem-categoria',
      orElse: () => models.Category(id: 'sem-categoria', name: 'Sem categoria'),
    );

    // Only consider reorderable categories (exclude sem-categoria)
    final others = _categories.where((c) => c.id != 'sem-categoria').toList();

    final active = <models.Category>[];
    final completed = <models.Category>[];
    for (final c in others) {
      if (isCategoryCompleted(c.id)) {
        completed.add(c);
      } else {
        active.add(c);
      }
    }

    final newOrder = [sem, ...active, ...completed];

    // Check if order changed (compare ids)
    final same =
        newOrder.length == _categories.length &&
        Iterable.generate(
          newOrder.length,
        ).every((i) => newOrder[i].id == _categories[i].id);

    if (same) return;

    _categories = newOrder;

    // Update sortOrder values to persist the order (sem-categoria at 0)
    for (var i = 0; i < _categories.length; i++) {
      _categories[i] = _categories[i].copyWith(sortOrder: i);
    }

    await _updateActiveListTimestamp();
    await _repository.saveCategories(_activeListId!, _categories);
    notifyListeners();
  }

  /// Limpa todos os dados (para testes)
  Future<void> clearAll() async {
    _shoppingLists = [];
    _categories = [];
    _items = [];
    _activeListId = null;
    await _repository.clearAll();
    notifyListeners();
  }

  /// Updates the lastModifiedAt timestamp for the current active list
  Future<void> _updateActiveListTimestamp() async {
    if (_activeListId == null) return;
    final index = _shoppingLists.indexWhere((list) => list.id == _activeListId);
    if (index == -1) return;

    _shoppingLists[index] = _shoppingLists[index].copyWith(
      lastModifiedAt: DateTime.now(),
    );
    await _repository.saveShoppingLists(
      _shoppingLists,
      _userIdentityService.currentOwnerId,
    );
  }

  @override
  void dispose() {
    _createListSyncSubscription?.cancel();
    _createCategorySyncSubscription?.cancel();
    _createItemSyncSubscription?.cancel();
    super.dispose();
  }
}
