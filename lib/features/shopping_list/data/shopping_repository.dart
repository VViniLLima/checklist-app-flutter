import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/shopping_item.dart';

/// Repositório responsável por persistir e recuperar dados da lista de compras
/// 
/// Utiliza shared_preferences para armazenamento local simples
/// Serializa categorias e itens como JSON
class ShoppingRepository {
  static const String _categoriesKey = 'shopping_categories';
  static const String _itemsKey = 'shopping_items';

  final SharedPreferences _prefs;

  ShoppingRepository(this._prefs);

  /// Factory para criar instância do repositório de forma assíncrona
  static Future<ShoppingRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ShoppingRepository(prefs);
  }

  // ==================== Categories ====================

  /// Salva lista de categorias no armazenamento local
  Future<void> saveCategories(List<Category> categories) async {
    final jsonList = categories.map((c) => c.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_categoriesKey, jsonString);
  }

  /// Carrega lista de categorias do armazenamento local
  Future<List<Category>> loadCategories() async {
    final jsonString = _prefs.getString(_categoriesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Em caso de erro de deserialização, retorna lista vazia
      return [];
    }
  }

  // ==================== Items ====================

  /// Salva lista de itens no armazenamento local
  Future<void> saveItems(List<ShoppingItem> items) async {
    final jsonList = items.map((item) => item.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_itemsKey, jsonString);
  }

  /// Carrega lista de itens do armazenamento local
  Future<List<ShoppingItem>> loadItems() async {
    final jsonString = _prefs.getString(_itemsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => ShoppingItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Em caso de erro de deserialização, retorna lista vazia
      return [];
    }
  }

  // ==================== Limpeza ====================

  /// Limpa todos os dados salvos (útil para testes ou reset)
  Future<void> clearAll() async {
    await _prefs.remove(_categoriesKey);
    await _prefs.remove(_itemsKey);
  }
}
