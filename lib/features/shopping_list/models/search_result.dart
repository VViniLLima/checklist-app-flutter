enum SearchResultType { list, category, item }

class SearchResult {
  final SearchResultType type;
  final String listId;
  final String listName;
  final String? categoryId;
  final String? categoryName;
  final String? itemId;
  final String? itemName;

  SearchResult({
    required this.type,
    required this.listId,
    required this.listName,
    this.categoryId,
    this.categoryName,
    this.itemId,
    this.itemName,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult &&
        other.type == type &&
        other.listId == listId &&
        other.categoryId == categoryId &&
        other.itemId == itemId;
  }

  @override
  int get hashCode => Object.hash(type, listId, categoryId, itemId);
}
