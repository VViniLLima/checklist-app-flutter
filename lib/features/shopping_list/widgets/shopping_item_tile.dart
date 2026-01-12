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

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggleCheck,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: item.isChecked ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isChecked ? Colors.grey.shade300 : Colors.grey.shade200,
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
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
          tooltip: 'Remover item',
        ),
      ),
    );
  }
}
