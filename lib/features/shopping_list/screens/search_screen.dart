import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/shopping_list_controller.dart';
import '../state/search_controller.dart' as search_ctrl;
import '../models/search_result.dart';
import 'shopping_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) return;
    context.read<search_ctrl.SearchController>().addRecentSearch(query);
    context.read<search_ctrl.SearchController>().performSearch(query);
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Buscar produtos, listas ou categorias',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: colorScheme.primary,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<search_ctrl.SearchController>()
                                        .performSearch('');
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                          context
                              .read<search_ctrl.SearchController>()
                              .performSearch(value);
                        },
                        onSubmitted: _onSearch,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Consumer<search_ctrl.SearchController>(
                builder: (context, controller, child) {
                  if (_searchController.text.isEmpty) {
                    return _buildEmptyState(context, controller);
                  }

                  if (controller.isSearching) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.results.isEmpty) {
                    return _buildNoResults(context);
                  }

                  return _buildResultsList(context, controller.results);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    search_ctrl.SearchController controller,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Buscas recentes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => controller.clearRecentSearches(),
                  child: const Text('Limpar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.recentSearches.map((query) {
                return ActionChip(
                  label: Text(query),
                  onPressed: () {
                    _searchController.text = query;
                    _onSearch(query);
                  },
                  backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.manage_search_rounded,
                  size: 80,
                  color: colorScheme.onSurface.withOpacity(0.05),
                ),
                const SizedBox(height: 16),
                Text(
                  'Encontre o que você precisa',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum resultado encontrado',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente buscar por outro termo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, List<SearchResult> results) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildResultCard(context, result);
      },
    );
  }

  Widget _buildResultCard(BuildContext context, SearchResult result) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData icon;
    String typeLabel;
    Color typeColor;
    String subtitle;

    switch (result.type) {
      case SearchResultType.list:
        icon = Icons.receipt_long_rounded;
        typeLabel = 'Lista';
        typeColor = colorScheme.primary;
        subtitle = 'Lista de compras';
        break;
      case SearchResultType.category:
        icon = Icons.category_outlined;
        typeLabel = 'Categoria';
        typeColor = colorScheme.secondary;
        subtitle = 'Na lista: ${result.listName}';
        break;
      case SearchResultType.item:
        icon = Icons.shopping_bag_outlined;
        typeLabel = 'Item';
        typeColor = colorScheme.tertiary;
        subtitle = '${result.itemName} • ${result.categoryName}';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToResult(context, result),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              result.type == SearchResultType.list
                                  ? result.listName
                                  : (result.type == SearchResultType.category
                                        ? result.categoryName!
                                        : result.itemName!),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withOpacity(0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToResult(BuildContext context, SearchResult result) async {
    // Add to recent searches
    final query = _searchController.text;
    if (query.isNotEmpty) {
      context.read<search_ctrl.SearchController>().addRecentSearch(query);
    }

    // Set active list
    final shoppingController = context.read<ShoppingListController>();
    await shoppingController.setActiveList(result.listId);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ShoppingListScreen(
            focusCategoryId: result.categoryId,
            focusItemId: result.itemId,
          ),
        ),
      );
    }
  }
}
