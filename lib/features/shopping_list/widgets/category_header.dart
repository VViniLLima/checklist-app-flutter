import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
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

  const CategoryHeader({
    super.key,
    this.category,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onAddItem,
    this.onEditCategory,
    this.showDragHandle = false,
  });

  Color _getTextColor(Color backgroundColor) {
  // Map shade50 colors to their base colors
// Define category title color
  const categoryTitle = Color(0xfff8f3ed); // creme
  
  final colorMap = {
    Color(0xff0f408f): categoryTitle, // azul escuro -> creme
    Color(0xffbce4fe): categoryTitle, // azul claro -> creme
    Color(0xff89aeff): categoryTitle, // lilas claro -> creme
    Color(0xffef7148): categoryTitle, // laranja -> creme
    Color(0xffdffc8e): Color(0xff0f408f) //categoryTitle, // verde -> creme
  };

  return colorMap[backgroundColor] ?? Colors.blue;
}

  @override
  Widget build(BuildContext context) {
    final categoryName = category?.name ?? 'Sem categoria';
    final backgroundColor = category?.color ?? Color(0xff0f408f);
    //final backgroundColor = category !=null ?_getTextColor(backgroundColor) : Color(0xfff8f3ed);

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleCollapse,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Row(
              children: [
                // Ícone de colapso (chevron com rotação)
                AnimatedRotation(
                  turns: isCollapsed ? -0.25 : 0, // -90° quando colapsado
                  duration: const Duration(milliseconds: 200),
                  child:  Icon(
                    Icons.expand_more,
                    color: _getTextColor(backgroundColor),
                  ),
                ),
                const SizedBox(width: 12),
                if (showDragHandle) ...[
                  Tooltip(
                    message: 'Pressione e segure para reordenar',
                    child: Icon(
                      Icons.drag_handle,
                      color: _getTextColor(backgroundColor) ,
                      
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Nome da categoria
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      //color: Color(0xfff8f3ed),
                      color: _getTextColor(backgroundColor),
                    ),
                  ),
                ),
                
                // Botão para adicionar item
                IconButton(
                  icon:  Icon(Icons.add_circle_outline),
                  color: _getTextColor(backgroundColor),
                  onPressed: onAddItem,
                  tooltip: 'Adicionar item',
                ),
                if (onEditCategory != null)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.edit_outlined, color: _getTextColor(backgroundColor)),
                    tooltip: 'Editar categoria',
                    onSelected: (value) {
                      if (value == 'rename') {
                        onEditCategory!();
                      } else if (value == 'color') {
                        _showColorPicker(context);
                      }
                    },
                    itemBuilder: (context) {
                      // For "Sem categoria", only show color option
                      final isSemCategoria = category?.id == 'sem-categoria';
                      if (isSemCategoria) {
                        return [
                          const PopupMenuItem(
                            value: 'color',
                            child: Row(
                              children: [
                                Icon(Icons.palette, size: 20),
                                SizedBox(width: 8),
                                Text('Mudar cor'),
                              ],
                            ),
                          ),
                        ];
                      }
                      // For other categories, show both options
                      return [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Renomear'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'color',
                          child: Row(
                            children: [
                              Icon(Icons.palette, size: 20),
                              SizedBox(width: 8),
                              Text('Mudar cor'),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    if (category == null) return;

    // 8 tons de azul similares ao blue.shade50
    final colors = [
      Color(0xff0f408f), // azul escuro
      Color(0xffbce4fe), // azul claro
      Color(0xff89aeff), // lilas claro
      Color(0xffef7148), // laranja
      Color(0xffdffc8e), 
      //Colors.blue.shade50,
      // Colors.lightBlue.shade50,
      // Colors.cyan.shade50,
      // Colors.teal.shade50,
      // Colors.indigo.shade50,
      // Colors.purple.shade50,
      // Colors.pink.shade50,
      // Colors.red.shade50,
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Escolher cor'),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              final isSelected = category!.colorValue == color.value;
              return InkWell(
                onTap: () {
                  final controller = context.read<ShoppingListController>();
                  controller.editCategoryColor(category!.id, color.value);
                  Navigator.of(dialogContext).pop();
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
