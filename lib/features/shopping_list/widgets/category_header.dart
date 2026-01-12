import 'package:flutter/material.dart';
import '../models/category.dart';

/// Widget que exibe o cabeçalho de uma categoria
/// 
/// Features:
/// - Texto em negrito com fundo destacado
/// - Ícone de colapso (chevron) que rotaciona
/// - Ação de tap para expandir/colapsar
/// - Botões para adicionar item e editar categoria
/// - Indicação visual de arraste quando reordenável
class CategoryHeader extends StatelessWidget {
  final Category? category; // null = "Sem categoria"
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onAddItem;
  final VoidCallback? onEditCategory; // null para "Sem categoria"
  final bool showDragHandle;

  const CategoryHeader({
    super.key,
    this.category,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onAddItem,
    this.onEditCategory,
    this.showDragHandle = false,
  });

  @override
  Widget build(BuildContext context) {
    final categoryName = category?.name ?? 'Sem categoria';

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleCollapse,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Ícone de colapso (chevron com rotação)
                AnimatedRotation(
                  turns: isCollapsed ? -0.25 : 0, // -90° quando colapsado
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.expand_more,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                if (showDragHandle) ...[
                  Tooltip(
                    message: 'Pressione e segure para reordenar',
                    child: const Icon(
                      Icons.drag_handle,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Nome da categoria
                Expanded(
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                
                // Botão para adicionar item
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.blue,
                  onPressed: onAddItem,
                  tooltip: 'Adicionar item',
                ),
                if (onEditCategory != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.blue,
                    onPressed: onEditCategory,
                    tooltip: 'Editar categoria',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
