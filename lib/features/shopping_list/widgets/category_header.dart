import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/shopping_item.dart';
import '../state/shopping_list_controller.dart';

/// Widget que exibe o cabeçalho de uma categoria
///
/// Features:
/// - Texto em negrito com fundo destacado
/// - Ícone de colapso (chevron) que rotaciona
/// - Ação de tap para expandir/colapsar
/// - Botões para adicionar item e editar categoria
/// - Indicação visual de arraste quando reordenável
/// - Seletor de cor para personalizar o fundo da categoria
class CategoryHeader extends StatelessWidget {
  final Category? category; // null = "Sem categoria"
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onAddItem;
  final VoidCallback? onEditCategory; // null para "Sem categoria"
  final bool showDragHandle;
  final bool isHighlighted;

  const CategoryHeader({
    super.key,
    this.category,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onAddItem,
    this.onEditCategory,
    this.showDragHandle = false,
    this.isHighlighted = false,
  });

  Color _getTextColor(Color backgroundColor) {
    // Determine if white or black text is better based on luminance
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = context.watch<ShoppingListController>();
    final items = controller.getItemsByCategory(category?.id);
    final totalItems = ShoppingItem.getTotalCount(items);
    final completedItems = ShoppingItem.getCompletedCount(items);

    final categoryName = category?.name ?? 'Sem categoria';
    final backgroundColor = category?.color ?? colorScheme.primary;
    final textColor = _getTextColor(backgroundColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      decoration: BoxDecoration(
        color: isHighlighted
            ? backgroundColor.withOpacity(0.25)
            : backgroundColor.withOpacity(
                theme.brightness == Brightness.light ? 0.08 : 0.15,
              ),
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: backgroundColor, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleCollapse,
          onLongPress: () => _showLongPressMenu(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Cor da categoria como indicador lateral
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),

                // Nome da categoria
                Expanded(
                  child: Text(
                    categoryName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),

                // Pill de contagem
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$completedItems/$totalItems',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),

                // Botão para adicionar item
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  color: backgroundColor,
                  onPressed: onAddItem,
                  padding: const EdgeInsets.only(left: 8),
                  constraints: const BoxConstraints(),
                  tooltip: 'Adicionar item',
                ),

                // Ícone de colapso
                AnimatedRotation(
                  turns: isCollapsed ? -0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    color: colorScheme.onSurface.withOpacity(0.3),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLongPressMenu(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isSemCategoria = category?.id == 'sem-categoria';
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (!isSemCategoria && onEditCategory != null)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Renomear categoria'),
                  onTap: () {
                    Navigator.pop(context);
                    onEditCategory!();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Mudar cor'),
                onTap: () {
                  Navigator.pop(context);
                  _showColorPicker(context);
                },
              ),
              if (!isSemCategoria)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Excluir categoria',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteCategory(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context) {
    final controller = context.read<ShoppingListController>();
    final itemsInGroup = controller.getItemsByCategory(category?.id);

    if (itemsInGroup.isEmpty) {
      if (category?.id != null) {
        controller.deleteCategory(category!.id);
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir categoria?'),
        content: const Text(
          'Esta categoria possui alguns itens, tem certeza de que deseja excluí-la e todos os seus itens?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (category?.id != null) {
                controller.deleteCategory(category!.id);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = context.read<ShoppingListController>();

    // Palette colors from design system
    final colors = [
      colorScheme.primary, // Dark Blue (Primary)
      const Color(0xFF179BE6), // Secondary Blue
      const Color(0xFF10B981), // Success Green
      const Color(0xFFEC9A3A), // Warning Orange
      const Color(0xFFE05252), // Error Coral
      const Color(0xFF9052E0), // Purple
      const Color(0xFF00C9BD), // Accent Turquoise
      const Color(0xFF0E1A2B), // Text Primary (Near Black)
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolha uma cor'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: colors.map((color) {
              final isSelected = category?.color.value == color.value;
              return InkWell(
                onTap: () {
                  controller.editCategoryColor(
                    category?.id ?? 'sem-categoria',
                    color.value,
                  );
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.onSurface
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 16, color: _getTextColor(color))
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
