import 'package:intl/intl.dart';
import '../models/shopping_list.dart';
import '../models/n8n_response.dart';
import '../state/shopping_list_controller.dart';

class N8nListBuilderService {
  final ShoppingListController controller;

  N8nListBuilderService(this.controller);

  /// Normalizes a name for deduplication: trim, lowercase, collapse multiple spaces.
  String _normalizeName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Builds and saves a shopping list from a list of selected meals.
  Future<ShoppingList?> buildAndSaveList(
    List<N8nMeal> selectedMeals, {
    String? customName,
  }) async {
    if (selectedMeals.isEmpty) return null;

    final String timestamp = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(DateTime.now());
    final String listName = customName ?? 'Lista importada - $timestamp';

    // 1. Create the new list
    await controller.addShoppingList(listName);

    // Get the newly created list (it should be the last one in the controller)
    final newList = controller.shoppingLists.last;

    // 2. Set it as active so we can add categories and items to it
    await controller.setActiveList(newList.id);

    // 3. Collect unique items and categories
    final Map<String, N8nMealItem> deduplicatedItems = {};
    final Set<String> categoriesToCreate = {};

    for (var meal in selectedMeals) {
      for (var n8nItem in meal.itens) {
        final normalized = _normalizeName(n8nItem.item);
        if (!deduplicatedItems.containsKey(normalized)) {
          deduplicatedItems[normalized] = n8nItem;
        }

        if (n8nItem.categoria.isNotEmpty &&
            n8nItem.categoria != 'Sem categoria') {
          categoriesToCreate.add(n8nItem.categoria);
        }
      }
    }

    // 4. Create categories
    final Map<String, String> categoryNameToId = {};

    // First, map existing "Sem categoria"
    final semCategoria = controller.semCategoria;
    if (semCategoria != null) {
      categoryNameToId['Sem categoria'] = semCategoria.id;
      categoryNameToId[''] = semCategoria.id;
    }

    for (var catName in categoriesToCreate) {
      await controller.addCategory(catName);
      // After adding, the last category in the list should be the one we just added
      categoryNameToId[catName] = controller.categories.last.id;
    }

    // 5. Add items to their respective categories
    for (var entry in deduplicatedItems.entries) {
      final n8nItem = entry.value;
      final categoryId = categoryNameToId[n8nItem.categoria] ?? 'sem-categoria';

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
}
