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
  final VoidCallback onSwipeComplete;
  final VoidCallback onSwipeDelete;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggleCheck,
    required this.onDelete,
    required this.onEdit,
    required this.onSwipeComplete,
    required this.onSwipeDelete,
  });

  @override
  Widget build(BuildContext context) {
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
          color: Colors.green.shade400,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Concluir',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Excluir',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: item.isChecked ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: item.isChecked ? Colors.grey.shade100 : const Color.fromARGB(0, 238, 238, 238),
          ),
        ),
        child: ListTile(
          leading: Checkbox(
            value: item.isChecked,
            onChanged: (_) => onToggleCheck(),
            activeColor: Colors.green,
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontSize: 16,
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
              color: item.isChecked ? Colors.grey.shade600 : Colors.black87,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: onEdit,
                tooltip: 'Editar item',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Remover item',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
