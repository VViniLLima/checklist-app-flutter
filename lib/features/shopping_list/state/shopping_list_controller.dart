import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../models/shopping_item.dart';
import '../models/shopping_list.dart';
import '../data/shopping_repository.dart';

/// Controller principal que gerencia o estado da lista de compras
/// 
/// Implementa todas as regras de negócio:
/// - Gerenciar múltiplas listas de compras
/// - Adicionar/remover categorias e itens
/// - Marcar/desmarcar itens (com reordenação automática)
/// - Colapsar/expandir categorias
/// - Persistir mudanças automaticamente
class ShoppingListController extends ChangeNotifier {
  final ShoppingRepository _repository;

  List<ShoppingList> _shoppingLists = [];
  String? _activeListId;
  List<models.Category> _categories = [];
  List<ShoppingItem> _items = [];
  bool _isLoading = true;

  ShoppingListController(this._repository);

  // ==================== Getters ====================

  bool get isLoading => _isLoading;
  List<ShoppingList> get shoppingLists => List.unmodifiable(_shoppingLists);
  String? get activeListId => _activeListId;
  ShoppingList? get activeList {
    if (_activeListId == null) return null;
    try {
      return _shoppingLists.firstWhere((list) => list.id == _activeListId);
    } catch (e) {
      return null;
    }
  }

  List<models.Category> get categories => List.unmodifiable(
    _categories.where((cat) => cat.id != 'sem-categoria'),
  );
  List<ShoppingItem> get allItems => List.unmodifiable(_items);

  /// Retorna itens de uma categoria específica, ordenados conforme regras:
  /// - Itens NÃO marcados primeiro (ordenados por createdAt)
  /// - Itens marcados no final (ordenados por checkedAt)
  List<ShoppingItem> getItemsByCategory(String? categoryId) {
    final categoryItems =
        _items.where((item) => item.categoryId == categoryId).toList();

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
      // Check if migration is needed
      if (await _repository.needsMigration()) {
        final migratedList = await _repository.migrateOldData();
        if (migratedList != null) {
          _shoppingLists = [migratedList];
          _activeListId = migratedList.id;
        }
      } else {
        _shoppingLists = await _repository.loadShoppingLists();
        _activeListId = _repository.loadActiveListId();
      }

      // If no lists exist, create default list
      if (_shoppingLists.isEmpty) {
        final defaultList = ShoppingList(
          id: 'list-1',
          name: 'Lista de compras 1',
          createdAt: DateTime.now(),
        );
        _shoppingLists = [defaultList];
        _activeListId = defaultList.id;
        await _repository.saveShoppingLists(_shoppingLists);
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

  /// Carrega dados de uma lista específica
  Future<void> _loadListData(String listId) async {
    _categories = await _repository.loadCategories(listId);
    _items = await _repository.loadItems(listId);
    _ensureSemCategoriaExists();
  }

  void _ensureSemCategoriaExists() {
    const semCategoriaId = 'sem-categoria';
    final semCategoriaExists = _categories.any((cat) => cat.id == semCategoriaId);
    if (!semCategoriaExists) {
      final semCategoria = models.Category(
        id: semCategoriaId,
        name: 'Sem categoria',
      );
      _categories.insert(0, semCategoria); // Insert at beginning
      if (_activeListId != null) {
        _repository.saveCategories(_activeListId!, _categories); // Save immediately
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

  /// Adiciona nova lista de compras
  Future<void> addShoppingList(String name) async {
    final newList = ShoppingList(
      id: 'list-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      createdAt: DateTime.now(),
    );

    _shoppingLists.add(newList);
    await _repository.saveShoppingLists(_shoppingLists);
    notifyListeners();
  }

  /// Define a lista ativa e carrega seus dados
  Future<void> setActiveList(String listId) async {
    if (_activeListId == listId) return;

    _activeListId = listId;
    await _repository.saveActiveListId(listId);
    await _loadListData(listId);
    notifyListeners();
  }

  // ==================== Categorias ====================

  /// Adiciona nova categoria
  Future<void> addCategory(String name) async {
    if (_activeListId == null) return;

    final newCategory = models.Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );

    _categories.add(newCategory);
    await _repository.saveCategories(_activeListId!, _categories);
    notifyListeners();
  }

  /// Remove categoria (itens ficam sem categoria)
  Future<void> removeCategory(String categoryId) async {
    if (_activeListId == null) return;

    _categories.removeWhere((cat) => cat.id == categoryId);
    
    // Move itens da categoria removida para "Sem categoria"
    _items = _items.map((item) {
      if (item.categoryId == categoryId) {
        return item.copyWith(categoryId: 'sem-categoria');
      }
      return item;
    }).toList();

    await _repository.saveCategories(_activeListId!, _categories);
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();
  }

  /// Edita o nome de uma categoria existente
  Future<void> editCategory(String categoryId, String newName) async {
    if (_activeListId == null) return;

    _categories = _categories.map((cat) {
      if (cat.id == categoryId) {
        return cat.copyWith(name: newName);
      }
      return cat;
    }).toList();

    await _repository.saveCategories(_activeListId!, _categories);
    notifyListeners();
  }

  /// Edita a cor de uma categoria existente
  Future<void> editCategoryColor(String categoryId, int colorValue) async {
    if (_activeListId == null) return;

    _categories = _categories.map((cat) {
      if (cat.id == categoryId) {
        return cat.copyWith(colorValue: colorValue);
      }
      return cat;
    }).toList();

    await _repository.saveCategories(_activeListId!, _categories);
    notifyListeners();
  }

  /// Alterna estado de colapso de uma categoria
  Future<void> toggleCategoryCollapse(String categoryId) async {
    if (_activeListId == null) return;

    _categories = _categories.map((cat) {
      if (cat.id == categoryId) {
        return cat.copyWith(isCollapsed: !cat.isCollapsed);
      }
      return cat;
    }).toList();

    await _repository.saveCategories(_activeListId!, _categories);
    notifyListeners();
  }

  /// Reordena categorias mantendo "Sem categoria" fora da lista reordenavel
  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (_activeListId == null) return;
    if (oldIndex == newIndex) return;
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Get only reorderable categories (excluding sem-categoria)
    final reorderableCategories = _categories.where((cat) => cat.id != 'sem-categoria').toList();
    final moved = reorderableCategories.removeAt(oldIndex);
    reorderableCategories.insert(newIndex, moved);

    // Rebuild full list with sem-categoria at the beginning
    final semCategoria = _categories.firstWhere((cat) => cat.id == 'sem-categoria');
    _categories = [semCategoria, ...reorderableCategories];

    await _repository.saveCategories(_activeListId!, _categories);
    notifyListeners();
  }

  // ==================== Itens ====================

  /// Adiciona novo item a uma categoria (ou sem categoria se categoryId for null)
  Future<void> addItem(String name, String? categoryId) async {
    if (_activeListId == null) return;

    final newItem = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      categoryId: categoryId,
      createdAt: DateTime.now(),
    );

    _items.add(newItem);
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();
  }

  /// Remove item da lista
  Future<void> removeItem(String itemId) async {
    if (_activeListId == null) return;

    _items.removeWhere((item) => item.id == itemId);
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();
  }

  /// Edita o nome de um item existente
  /// Mantém o estado checked, categoria e timestamps
  Future<void> editItem(String itemId, String newName) async {
    if (_activeListId == null) return;

    _items = _items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(name: newName);
      }
      return item;
    }).toList();

    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();
  }

  /// Marca/desmarca item
  /// 
  /// Quando marcado:
  /// - Define checkedAt para controlar ordenação
  /// - Item será automaticamente movido para o fim através da ordenação
  /// 
  /// Quando desmarcado:
  /// - Remove checkedAt
  /// - Item volta para o topo (entre os não marcados)
  Future<void> toggleItemCheck(String itemId) async {
    if (_activeListId == null) return;

    _items = _items.map((item) {
      if (item.id == itemId) {
        final newCheckedState = !item.isChecked;
        // Cria novo objeto para garantir que checkedAt seja null quando desmarcado
        return ShoppingItem(
          id: item.id,
          name: item.name,
          isChecked: newCheckedState,
          categoryId: item.categoryId,
          createdAt: item.createdAt,
          checkedAt: newCheckedState ? DateTime.now() : null,
        );
      }
      return item;
    }).toList();

    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();
  }

  /// Marca item como checked (ignora se ja estiver marcado)
  Future<void> markItemChecked(String itemId) async {
    if (_activeListId == null) return;

    var didUpdate = false;
    _items = _items.map((item) {
      if (item.id == itemId) {
        if (item.isChecked) return item;
        didUpdate = true;
        return ShoppingItem(
          id: item.id,
          name: item.name,
          isChecked: true,
          categoryId: item.categoryId,
          createdAt: item.createdAt,
          checkedAt: DateTime.now(),
        );
      }
      return item;
    }).toList();

    if (!didUpdate) return;
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();
  }

  /// Restaura um item removido (usado por Undo)
  Future<void> restoreItem(ShoppingItem item) async {
    if (_activeListId == null) return;

    _items.removeWhere((existing) => existing.id == item.id);
    _items.add(item);
    await _repository.saveItems(_activeListId!, _items);
    notifyListeners();
  }

  // ==================== Utilidades ====================

  /// Verifica se uma categoria está colapsada
  bool isCategoryCollapsed(String? categoryId) {
    if (categoryId == null) return false;
    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => const models.Category(id: '', name: '', isCollapsed: false),
    );
    return category.isCollapsed;
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
}
