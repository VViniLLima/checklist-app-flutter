import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_result.dart';
import '../state/shopping_list_controller.dart';
import '../../../core/utils/iterable_extensions.dart';

class SearchController extends ChangeNotifier {
  final ShoppingListController _shoppingController;
  final SharedPreferences _prefs;
  static const String _recentSearchesKey = 'recent_searches';

  List<String> _recentSearches = [];
  bool _isSearching = false;
  List<SearchResult> _results = [];

  SearchController(this._shoppingController, this._prefs) {
    _loadRecentSearches();
  }

  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  bool get isSearching => _isSearching;
  List<SearchResult> get results => List.unmodifiable(_results);

  void _loadRecentSearches() {
    _recentSearches = _prefs.getStringList(_recentSearchesKey) ?? [];
    notifyListeners();
  }

  Future<void> _saveRecentSearches() async {
    await _prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  void addRecentSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _recentSearches.removeWhere(
      (s) => s.toLowerCase() == trimmed.toLowerCase(),
    );
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }
    _saveRecentSearches();
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches = [];
    _saveRecentSearches();
    notifyListeners();
  }

  Future<void> performSearch(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final allResults = <SearchResult>[];
    final allLists = _shoppingController.shoppingLists;

    for (final list in allLists) {
      // 1. Check List Name
      if (list.name.toLowerCase().contains(q)) {
        allResults.add(
          SearchResult(
            type: SearchResultType.list,
            listId: list.id,
            listName: list.name,
          ),
        );
      }

      // Load data for this list to search categories and items
      final data = await _shoppingController.getHistoryListData(list.id);
      final categories = data['categories'] as List<dynamic>;
      final items = data['items'] as List<dynamic>;

      // 2. Check Categories
      for (final cat in categories) {
        if (cat.name.toLowerCase().contains(q)) {
          allResults.add(
            SearchResult(
              type: SearchResultType.category,
              listId: list.id,
              listName: list.name,
              categoryId: cat.id,
              categoryName: cat.name,
            ),
          );
        }
      }

      // 3. Check Items
      for (final item in items) {
        if (item.name.toLowerCase().contains(q)) {
          final cat = categories.firstWhereOrNull(
            (c) => c.id == item.categoryId,
          );
          allResults.add(
            SearchResult(
              type: SearchResultType.item,
              listId: list.id,
              listName: list.name,
              categoryId: item.categoryId,
              categoryName: cat?.name ?? 'Sem categoria',
              itemId: item.id,
              itemName: item.name,
            ),
          );
        }
      }
    }

    _results = allResults;
    _isSearching = false;
    notifyListeners();
  }
}
