import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/shopping_item.dart';
import 'category_header.dart';
import 'shopping_item_tile.dart';

/// Widget que representa uma seção completa de categoria
/// 
/// Inclui:
/// - Header com nome da categoria e botão de colapso
/// - Lista de itens (ordenados automaticamente pelo controller)
/// - Animação de expansão/colapso
class CategorySection extends StatelessWidget {
  final Category? category; // null = "Sem categoria"
  final List<ShoppingItem> items;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onAddItem;
  final VoidCallback? onEditCategory; // null para "Sem categoria"
  final Function(String itemId) onToggleItemCheck;
  final Function(String itemId) onDeleteItem;
  final Function(String itemId) onEditItem;
  final Function(ShoppingItem item) onSwipeComplete;
  final Function(ShoppingItem item) onSwipeDelete;
  final bool showDragHandle;
  final Widget Function(Widget header)? headerWrapper;

  const CategorySection({
    super.key,
    this.category,
    required this.items,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onAddItem,
    this.onEditCategory,
    required this.onToggleItemCheck,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onSwipeComplete,
    required this.onSwipeDelete,
    this.showDragHandle = false,
    this.headerWrapper,
  });

  @override
  Widget build(BuildContext context) {
    final header = CategoryHeader(
      category: category,
      isCollapsed: isCollapsed,
      onToggleCollapse: onToggleCollapse,
      onAddItem: onAddItem,
      onEditCategory: onEditCategory,
      showDragHandle: showDragHandle,
    );
    final wrappedHeader = headerWrapper != null ? headerWrapper!(header) : header;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header da categoria
        wrappedHeader,
        
        // Lista de itens (com animação de colapso)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isCollapsed
              ? const SizedBox.shrink()
              : Column(
                  children: items.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Nenhum item nesta categoria',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ]
                      : items.map((item) {
                       return ShoppingItemTile(
                         key: ValueKey(item.id),
                         item: item,
                         onToggleCheck: () => onToggleItemCheck(item.id),
                         onDelete: () => onDeleteItem(item.id),
                         onEdit: () => onEditItem(item.id),
                         onSwipeComplete: () => onSwipeComplete(item),
                         onSwipeDelete: () => onSwipeDelete(item),
                       );
                     }).toList(),
                ),
        ),
      ],
    );
  }
}
