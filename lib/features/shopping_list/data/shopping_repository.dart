import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/shopping_item.dart';
import '../models/shopping_list.dart';

/// Repositório responsável por persistir e recuperar dados da lista de compras
///
/// Utiliza shared_preferences para armazenamento local simples
/// Serializa categorias, itens e listas como JSON
class ShoppingRepository {
  static const String _categoriesKey = 'shopping_categories';
  static const String _itemsKey = 'shopping_items';
  static const String _listsKey = 'shopping_lists';
  static const String _activeListKey = 'active_shopping_list_id';

  final SharedPreferences _prefs;

  ShoppingRepository(this._prefs);

  /// Factory para criar instância do repositório de forma assíncrona
  static Future<ShoppingRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ShoppingRepository(prefs);
  }

  // ==================== Shopping Lists ====================

  /// Salva lista de listas de compras
  Future<void> saveShoppingLists(List<ShoppingList> lists) async {
    final jsonList = lists.map((l) => l.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_listsKey, jsonString);
  }

  /// Carrega lista de listas de compras
  Future<List<ShoppingList>> loadShoppingLists() async {
    final jsonString = _prefs.getString(_listsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => ShoppingList.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Salva o ID da lista ativa
  Future<void> saveActiveListId(String listId) async {
    await _prefs.setString(_activeListKey, listId);
  }

  /// Carrega o ID da lista ativa
  String? loadActiveListId() {
    return _prefs.getString(_activeListKey);
  }

  // ==================== Categories ====================

  /// Salva lista de categorias para uma lista específica
  Future<void> saveCategories(String listId, List<Category> categories) async {
    final key = '${_categoriesKey}_$listId';
    final jsonList = categories.map((c) => c.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(key, jsonString);
  }

  /// Carrega lista de categorias de uma lista específica
  Future<List<Category>> loadCategories(String listId) async {
    final key = '${_categoriesKey}_$listId';
    final jsonString = _prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== Items ====================

  /// Salva lista de itens para uma lista específica
  Future<void> saveItems(String listId, List<ShoppingItem> items) async {
    final key = '${_itemsKey}_$listId';
    final jsonList = items.map((item) => item.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(key, jsonString);
  }

  /// Carrega lista de itens de uma lista específica
  Future<List<ShoppingItem>> loadItems(String listId) async {
    final key = '${_itemsKey}_$listId';
    final jsonString = _prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => ShoppingItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== Migration ====================

  /// Migra dados antigos para o novo formato com múltiplas listas
  Future<bool> needsMigration() async {
    final hasOldCategories = _prefs.containsKey(_categoriesKey);
    final hasOldItems = _prefs.containsKey(_itemsKey);
    final hasNewLists = _prefs.containsKey(_listsKey);

    return (hasOldCategories || hasOldItems) && !hasNewLists;
  }

  /// Executa a migração dos dados antigos
  Future<ShoppingList?> migrateOldData() async {
    // Carrega dados antigos
    final oldCategoriesJson = _prefs.getString(_categoriesKey);
    final oldItemsJson = _prefs.getString(_itemsKey);

    if (oldCategoriesJson == null && oldItemsJson == null) {
      return null;
    }

    // Cria a primeira lista
    final firstList = ShoppingList(
      id: 'list-1',
      name: 'Lista de compras 1',
      createdAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
    );

    // Salva a lista
    await saveShoppingLists([firstList]);
    await saveActiveListId(firstList.id);

    // Migra categorias
    if (oldCategoriesJson != null && oldCategoriesJson.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(oldCategoriesJson);
        final categories = jsonList
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();
        await saveCategories(firstList.id, categories);
      } catch (e) {
        // Ignora erros de migração
      }
    }

    // Migra itens
    if (oldItemsJson != null && oldItemsJson.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(oldItemsJson);
        final items = jsonList
            .map((json) => ShoppingItem.fromJson(json as Map<String, dynamic>))
            .toList();
        await saveItems(firstList.id, items);
      } catch (e) {
        // Ignora erros de migração
      }
    }

    // Remove dados antigos
    await _prefs.remove(_categoriesKey);
    await _prefs.remove(_itemsKey);

    return firstList;
  }

  // ==================== Limpeza ====================

  /// Limpa todos os dados salvos (útil para testes ou reset)
  Future<void> clearAll() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('shopping_')) {
        await _prefs.remove(key);
      }
    }
  }
}
