import 'package:flutter/material.dart';
import '../models/shopping_item.dart';

/// Widget que exibe um item individual da lista de compras
///
/// Comportamento ao marcar:
/// - Checkbox fica verde com check
/// - Texto fica tachado (line-through)
/// - Background fica mais claro (indicando "concluído")
/// - Item é automaticamente reordenado para o fim (via controller)
class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggleCheck;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onMove;
  final VoidCallback? onCopy;
  final VoidCallback onSwipeComplete;
  final VoidCallback onSwipeDelete;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggleCheck,
    required this.onDelete,
    required this.onEdit,
    this.onMove,
    this.onCopy,
    required this.onSwipeComplete,
    required this.onSwipeDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Functional colors from design system (Success Green: #10B981, Error Coral: #E05252)
    const successColor = Color(0xFF10B981);
    const errorColor = Color(0xFFE05252);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (item.isChecked) return false;
          onSwipeComplete();
          return false;
        }
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onSwipeDelete();
        }
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: successColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Concluir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Excluir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: InkWell(
        onLongPress: () => _showLongPressMenu(context),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: item.isChecked
                ? colorScheme.surfaceVariant.withOpacity(0.3)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isChecked
                  ? colorScheme.outline.withOpacity(0.05)
                  : colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              if (!item.isChecked)
                BoxShadow(
                  color: Colors.black.withOpacity(
                    theme.brightness == Brightness.light ? 0.02 : 0.1,
                  ),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                Checkbox(
                  value: item.isChecked,
                  onChanged: (_) => onToggleCheck(),
                  activeColor: successColor,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: item.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.isChecked
                              ? colorScheme.onSurface.withOpacity(0.4)
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (item.quantityValue > 0)
                        Text(
                          '${item.quantityValue % 1 == 0 ? item.quantityValue.toInt() : item.quantityValue} ${item.quantityUnit}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                if (item.totalValue > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'R\$ ${item.totalValue.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: item.isChecked
                            ? colorScheme.onSurface.withOpacity(0.4)
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: colorScheme.onSurface.withOpacity(0.2),
                  ),
                  onPressed: onEdit,
                  tooltip: 'Editar item',
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
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.move_to_inbox_outlined),
              title: const Text('Move'),
              onTap: () {
                Navigator.pop(context);
                onMove?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                onCopy?.call();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text('Delete', style: TextStyle(color: colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
