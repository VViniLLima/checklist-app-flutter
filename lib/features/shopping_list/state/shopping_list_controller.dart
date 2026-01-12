import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../models/shopping_item.dart';
import '../data/shopping_repository.dart';

/// Controller principal que gerencia o estado da lista de compras
/// 
/// Implementa todas as regras de negócio:
/// - Adicionar/remover categorias e itens
/// - Marcar/desmarcar itens (com reordenação automática)
/// - Colapsar/expandir categorias
/// - Persistir mudanças automaticamente
class ShoppingListController extends ChangeNotifier {
  final ShoppingRepository _repository;

  List<models.Category> _categories = [];
  List<ShoppingItem> _items = [];
  bool _isLoading = true;

  ShoppingListController(this._repository);

  // ==================== Getters ====================

  bool get isLoading => _isLoading;
  List<models.Category> get categories => List.unmodifiable(_categories);
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
      _categories = await _repository.loadCategories();
      _items = await _repository.loadItems();
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      _categories = [];
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== Categorias ====================

  /// Adiciona nova categoria
  Future<void> addCategory(String name) async {
    final newCategory = models.Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );

    _categories.add(newCategory);
    await _repository.saveCategories(_categories);
    notifyListeners();
  }

  /// Remove categoria (itens ficam sem categoria)
  Future<void> removeCategory(String categoryId) async {
    _categories.removeWhere((cat) => cat.id == categoryId);
    
    // Move itens da categoria removida para "Sem categoria"
    _items = _items.map((item) {
      if (item.categoryId == categoryId) {
        return item.copyWith(categoryId: null);
      }
      return item;
    }).toList();

    await _repository.saveCategories(_categories);
    await _repository.saveItems(_items);
    notifyListeners();
  }

  /// Edita o nome de uma categoria existente
  Future<void> editCategory(String categoryId, String newName) async {
    _categories = _categories.map((cat) {
      if (cat.id == categoryId) {
        return cat.copyWith(name: newName);
      }
      return cat;
    }).toList();

    await _repository.saveCategories(_categories);
    notifyListeners();
  }

  /// Alterna estado de colapso de uma categoria
  Future<void> toggleCategoryCollapse(String categoryId) async {
    _categories = _categories.map((cat) {
      if (cat.id == categoryId) {
        return cat.copyWith(isCollapsed: !cat.isCollapsed);
      }
      return cat;
    }).toList();

    await _repository.saveCategories(_categories);
    notifyListeners();
  }

  // ==================== Itens ====================

  /// Adiciona novo item a uma categoria (ou sem categoria se categoryId for null)
  Future<void> addItem(String name, String? categoryId) async {
    final newItem = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      categoryId: categoryId,
      createdAt: DateTime.now(),
    );

    _items.add(newItem);
    await _repository.saveItems(_items);
    notifyListeners();
  }

  /// Remove item da lista
  Future<void> removeItem(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);
    await _repository.saveItems(_items);
    notifyListeners();
  }

  /// Edita o nome de um item existente
  /// Mantém o estado checked, categoria e timestamps
  Future<void> editItem(String itemId, String newName) async {
    _items = _items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(name: newName);
      }
      return item;
    }).toList();

    await _repository.saveItems(_items);
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

    await _repository.saveItems(_items);
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
    _categories = [];
    _items = [];
    await _repository.clearAll();
    notifyListeners();
  }
}
