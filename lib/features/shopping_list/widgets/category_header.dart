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
      Color(0xffdffc8e): Color(0xff0f408f), //categoryTitle, // verde -> creme
    };

    return colorMap[backgroundColor] ?? Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ShoppingListController>();
    final items = controller.getItemsByCategory(category?.id);
    final totalItems = items.length;
    final completedItems = items.where((i) => i.isChecked).length;

    final categoryName = category?.name ?? 'Sem categoria';
    final backgroundColor = category?.color ?? const Color(0xff0f408f);
    final textColor = _getTextColor(backgroundColor);

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade900,
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
                    color: Colors.blueGrey.shade400,
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
                    color: Colors.grey.shade300,
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
            ],
          ),
        );
      },
    );
  }

  void _showColorPicker(BuildContext context) {
    final controller = context.read<ShoppingListController>();
    final colors = [
      const Color(0xff0f408f), // Azul Marinho
      const Color(0xffd32f2f), // Vermelho
      const Color(0xff388e3c), // Verde
      const Color(0xfff57c00), // Laranja
      const Color(0xff7b1fa2), // Roxo
      const Color(0xff0097a7), // Ciano
      const Color(0xff455a64), // Blue Grey
      const Color(0xff6d4c41), // Marrom
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
                      color: (category?.color == color)
                          ? Colors.black
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
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
