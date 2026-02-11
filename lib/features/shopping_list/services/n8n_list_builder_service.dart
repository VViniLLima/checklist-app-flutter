import 'package:intl/intl.dart';
import '../models/shopping_list.dart';
import '../models/n8n_response.dart';
import '../state/shopping_list_controller.dart';

/// A curated palette of readable category background colors.
///
/// These are soft pastel shades that work well as category backgrounds
/// in both light and dark themes, derived from the app's color palette.
const List<int> _categoryColorPalette = [
  0xFFE3EFFF, // Light blue (primary light)
  0xFFE0F7F5, // Light teal (accent light)
  0xFFFFF3E0, // Light orange
  0xFFEDE7F6, // Light purple
  0xFFE8F5E9, // Light green
  0xFFFCE4EC, // Light pink
  0xFFFFF9C4, // Light yellow
  0xFFE0F2F1, // Light cyan
  0xFFF3E5F5, // Light magenta
  0xFFE8EAF6, // Light indigo
  0xFFFBE9E7, // Light deep orange
  0xFFEFEBE9, // Light brown
  0xFFE1F5FE, // Light sky blue
  0xFFF1F8E9, // Light lime
  0xFFFFF8E1, // Light amber
];

class N8nListBuilderService {
  final ShoppingListController controller;

  N8nListBuilderService(this.controller);

  /// Normalizes a name for deduplication: trim, lowercase, collapse multiple spaces,
  /// and remove common diacritical marks for better matching.
  String _normalizeName(String name) {
    var normalized = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    // Remove common Portuguese diacritics for dedup comparison
    normalized = _removeDiacritics(normalized);
    return normalized;
  }

  /// Removes common diacritical marks from a string.
  String _removeDiacritics(String str) {
    const diacritics = 'àáâãäåèéêëìíîïòóôõöùúûüýñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝÑÇ';
    const replacements =
        'aaaaaaeeeeiiiioooooouuuuyncAAAAAAEEEEIIIIOOOOOUUUUYNC';
    var result = str;
    for (var i = 0; i < diacritics.length; i++) {
      result = result.replaceAll(diacritics[i], replacements[i]);
    }
    return result;
  }

  /// Assigns a color from the palette to a category name deterministically.
  ///
  /// Uses a simple hash-based approach so the same category name always gets
  /// the same color within a single creation flow, while different categories
  /// get different colors (as much as possible).
  int _assignCategoryColor(String categoryName, int index) {
    // Use index-based assignment for variety, with hash as fallback
    if (index < _categoryColorPalette.length) {
      return _categoryColorPalette[index];
    }
    // For overflow, use hash of name to pick from palette
    final hash = categoryName.hashCode.abs();
    return _categoryColorPalette[hash % _categoryColorPalette.length];
  }

  /// Builds and saves a shopping list from a list of selected meals.
  ///
  /// Returns the created [ShoppingList] or null if no items were produced.
  /// Throws if selected meals yield zero items after deduplication.
  Future<ShoppingList?> buildAndSaveList(
    List<N8nMeal> selectedMeals, {
    String? customName,
  }) async {
    if (selectedMeals.isEmpty) return null;

    final String timestamp = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(DateTime.now());
    final String listName = customName ?? 'Lista importada - $timestamp';

    // 1. Collect unique items and categories with deduplication
    final Map<String, N8nMealItem> deduplicatedItems = {};
    final Map<String, String> normalizedToOriginalCategory = {};
    final Set<String> categoryNames = {};

    for (var meal in selectedMeals) {
      for (var n8nItem in meal.items) {
        final normalizedItemName = _normalizeName(n8nItem.item);
        if (!deduplicatedItems.containsKey(normalizedItemName)) {
          deduplicatedItems[normalizedItemName] = n8nItem;
        }

        final catName = n8nItem.category.trim();
        if (catName.isNotEmpty && catName != 'Sem categoria') {
          final normalizedCat = _normalizeName(catName);
          if (!normalizedToOriginalCategory.containsKey(normalizedCat)) {
            normalizedToOriginalCategory[normalizedCat] = catName;
            categoryNames.add(catName);
          }
        }
      }
    }

    // If deduplication yields zero items, return null
    if (deduplicatedItems.isEmpty) return null;

    // 2. Create the new list
    await controller.addShoppingList(listName);

    // Get the newly created list (it should be the last one in the controller)
    final newList = controller.shoppingLists.last;

    // 3. Set it as active so we can add categories and items to it
    await controller.setActiveList(newList.id);

    // 4. Create categories with palette-based colors
    final Map<String, String> categoryNameToId = {};

    // Map existing "Sem categoria"
    final semCategoria = controller.semCategoria;
    if (semCategoria != null) {
      categoryNameToId['Sem categoria'] = semCategoria.id;
      categoryNameToId[''] = semCategoria.id;
    }

    var colorIndex = 0;
    for (var catName in categoryNames) {
      // Assign a color from the palette
      final colorValue = _assignCategoryColor(catName, colorIndex);
      colorIndex++;

      await controller.addCategory(catName);
      // After adding, the last category in the list should be the one we just added
      final newCatId = controller.categories.last.id;
      categoryNameToId[catName] = newCatId;

      // Set the color for the newly created category
      await controller.editCategoryColor(newCatId, colorValue);
    }

    // 5. Add items to their respective categories
    for (var entry in deduplicatedItems.entries) {
      final n8nItem = entry.value;
      final catName = n8nItem.category.trim();
      final categoryId =
          categoryNameToId[catName] ??
          categoryNameToId['Sem categoria'] ??
          'sem-categoria';

      await controller.addItem(
        n8nItem.item,
        categoryId,
        quantityValue: 1.0,
        quantityUnit: 'und',
        priceValue: 0.0,
        totalValue: 0.0,
      );
    }

    return newList;
  }

  /// Counts the total number of unique items that would result from the
  /// given meal selection (after deduplication).
  ///
  /// Useful for previewing the result before creating the list.
  int countUniqueItems(List<N8nMeal> selectedMeals) {
    final Set<String> seen = {};
    for (var meal in selectedMeals) {
      for (var item in meal.items) {
        seen.add(_normalizeName(item.item));
      }
    }
    return seen.length;
  }
}
