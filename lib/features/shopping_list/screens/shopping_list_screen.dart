import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:checklist_app/main.dart';
import '../state/shopping_list_controller.dart';
import '../widgets/category_section.dart';
import '../widgets/shopping_list_summary_card.dart';
import '../models/shopping_item.dart';

/// Tela principal da lista de compras
///
/// Exibe:
/// - Seção "Sem categoria" (sempre visível)
/// - Todas as categorias criadas pelo usuário
/// - FAB para adicionar nova categoria
class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShoppingListController>(
      builder: (context, controller, _) {
        final activeList = controller.activeList;
        final listName = activeList?.name ?? 'Lista de Compras';

        return Scaffold(
          body: SafeArea(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      ShoppingListSummaryCard(
                        onRename: () => _showRenameListDialog(
                          context,
                          controller,
                          activeList?.id,
                          listName,
                        ),
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  CategorySection(
                                    category: controller.semCategoria,
                                    items: controller.getItemsByCategory(
                                      'sem-categoria',
                                    ),
                                    isCollapsed: false,
                                    onToggleCollapse: () {},
                                    onAddItem: () => _showItemEditorBottomSheet(
                                      context,
                                      categoryId: 'sem-categoria',
                                    ),
                                    onEditCategory: () {},
                                    onToggleItemCheck:
                                        controller.toggleItemCheck,
                                    onEditItem: (itemId) =>
                                        _showItemEditorBottomSheet(
                                          context,
                                          itemId: itemId,
                                        ),
                                    onDeleteItem: (itemId) => _confirmDelete(
                                      context,
                                      'Deseja remover este item?',
                                      () {
                                        final item = controller.allItems
                                            .firstWhere((i) => i.id == itemId);
                                        _performDeleteWithSnackBar(
                                          context,
                                          controller,
                                          item,
                                        );
                                      },
                                    ),
                                    onSwipeComplete: (item) =>
                                        controller.markItemChecked(item.id),
                                    onSwipeDelete: (item) => _handleSwipeDelete(
                                      context,
                                      controller,
                                      item,
                                    ),
                                    onMoveItem: (itemId) => _showCategoryPicker(
                                      context,
                                      (catId) async {
                                        await controller.moveItemToCategory(
                                          itemId,
                                          catId,
                                        );
                                      },
                                    ),
                                    onCopyItem: (itemId) => _showCategoryPicker(
                                      context,
                                      (catId) async {
                                        await controller.copyItemToCategory(
                                          itemId,
                                          catId,
                                        );
                                      },
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              sliver: SliverReorderableList(
                                itemCount: controller.categories.length,
                                onReorder: (oldIndex, newIndex) {
                                  controller.reorderCategories(
                                    oldIndex,
                                    newIndex,
                                  );
                                },
                                itemBuilder: (context, index) {
                                  final category = controller.categories[index];
                                  final items = controller.getItemsByCategory(
                                    category.id,
                                  );
                                  final isCollapsed = controller
                                      .isCategoryCollapsed(category.id);

                                  final isCompleted = controller
                                      .isCategoryCompleted(category.id);

                                  return Material(
                                    key: ValueKey(category.id),
                                    color: Colors.transparent,
                                    child: CategorySection(
                                      category: category,
                                      items: items,
                                      isCollapsed: isCollapsed,
                                      onToggleCollapse: () => controller
                                          .toggleCategoryCollapse(category.id),
                                      onAddItem: () =>
                                          _showItemEditorBottomSheet(
                                            context,
                                            categoryId: category.id,
                                          ),
                                      onEditCategory: () =>
                                          _showEditCategoryDialog(
                                            context,
                                            category.id,
                                            category.name,
                                          ),
                                      onToggleItemCheck:
                                          controller.toggleItemCheck,
                                      onEditItem: (itemId) =>
                                          _showItemEditorBottomSheet(
                                            context,
                                            itemId: itemId,
                                          ),
                                      onDeleteItem: (itemId) => _confirmDelete(
                                        context,
                                        'Deseja remover este item?',
                                        () {
                                          final item = controller.allItems
                                              .firstWhere(
                                                (i) => i.id == itemId,
                                              );
                                          _performDeleteWithSnackBar(
                                            context,
                                            controller,
                                            item,
                                          );
                                        },
                                      ),
                                      onSwipeComplete: (item) =>
                                          controller.markItemChecked(item.id),
                                      onSwipeDelete: (item) =>
                                          _handleSwipeDelete(
                                            context,
                                            controller,
                                            item,
                                          ),
                                      onMoveItem: (itemId) =>
                                          _showCategoryPicker(context, (
                                            catId,
                                          ) async {
                                            await controller.moveItemToCategory(
                                              itemId,
                                              catId,
                                            );
                                          }),
                                      onCopyItem: (itemId) =>
                                          _showCategoryPicker(context, (
                                            catId,
                                          ) async {
                                            await controller.copyItemToCategory(
                                              itemId,
                                              catId,
                                            );
                                          }),
                                      showDragHandle: !isCompleted,
                                      headerWrapper: !isCompleted
                                          ? (header) =>
                                                ReorderableDelayedDragStartListener(
                                                  index: index,
                                                  child: header,
                                                )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  24,
                                  16,
                                  120,
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {}, // No-op for now
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6342E8),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      double.infinity,
                                      56,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  label: const Text(
                                    'Finalizar lista',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddCategoryDialog(context),
            backgroundColor: const Color(0xFF6342E8),
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            label: const Text(
              'Nova Categoria',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  /// Exibe dialog para renomear a lista de compras
  void _showRenameListDialog(
    BuildContext context,
    ShoppingListController controller,
    String? listId,
    String currentName,
  ) {
    if (listId == null) return;
    final textController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear Lista'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da lista',
            hintText: 'Ex: Compras do mês, Feira...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              controller.renameShoppingList(listId, value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('O nome da lista não pode estar vazio'),
                  ),
                );
                return;
              }
              controller.renameShoppingList(listId, name);
              Navigator.of(context).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _handleSwipeDelete(
    BuildContext context,
    ShoppingListController controller,
    ShoppingItem item,
  ) {
    _performDeleteWithSnackBar(context, controller, item);
  }

  /// Centralized delete + SnackBar + Undo helper
  void _performDeleteWithSnackBar(
    BuildContext context,
    ShoppingListController controller,
    ShoppingItem item,
  ) {
    controller.removeItem(item.id);

    final messenger =
        scaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Item removido'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => controller.restoreItem(item),
        ),
      ),
    );
  }

  /// Exibe dialog para adicionar nova categoria
  void _showAddCategoryDialog(BuildContext context) {
    final controller = context.read<ShoppingListController>();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Categoria'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da categoria',
            hintText: 'Ex: Mercearia, Hortifruti...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              final trimmedName = value.trim();
              // Verifica se o nome já existe
              final isDuplicate = controller.categories.any(
                (cat) => cat.name.toLowerCase() == trimmedName.toLowerCase(),
              );

              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Já existe uma categoria com este nome'),
                  ),
                );
                return;
              }

              controller.addCategory(trimmedName);
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('O nome da categoria não pode estar vazio'),
                  ),
                );
                return;
              }

              // Verifica se o nome já existe
              final isDuplicate = controller.categories.any(
                (cat) => cat.name.toLowerCase() == name.toLowerCase(),
              );

              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Já existe uma categoria com este nome'),
                  ),
                );
                return;
              }

              controller.addCategory(name);
              Navigator.of(context).pop();
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  /// Exibe dialog para editar categoria existente
  void _showEditCategoryDialog(
    BuildContext context,
    String categoryId,
    String currentName,
  ) {
    final controller = context.read<ShoppingListController>();
    final textController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Categoria'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da categoria',
            hintText: 'Ex: Mercearia, Hortifruti...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              final trimmedName = value.trim();
              // Verifica se o nome já existe em outra categoria
              final isDuplicate = controller.categories.any(
                (cat) =>
                    cat.id != categoryId &&
                    cat.name.toLowerCase() == trimmedName.toLowerCase(),
              );

              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Já existe uma categoria com este nome'),
                  ),
                );
                return;
              }

              controller.editCategory(categoryId, trimmedName);
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('O nome da categoria não pode estar vazio'),
                  ),
                );
                return;
              }

              // Verifica se o nome já existe em outra categoria
              final isDuplicate = controller.categories.any(
                (cat) =>
                    cat.id != categoryId &&
                    cat.name.toLowerCase() == name.toLowerCase(),
              );

              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Já existe uma categoria com este nome'),
                  ),
                );
                return;
              }

              controller.editCategory(categoryId, name);
              Navigator.of(context).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  /// Exibe bottom sheet para editar ou criar todos os campos do item
  void _showItemEditorBottomSheet(
    BuildContext context, {
    String? itemId,
    String? categoryId,
  }) {
    final controller = context.read<ShoppingListController>();
    final isEditing = itemId != null;

    final item = isEditing
        ? controller.allItems.firstWhere((i) => i.id == itemId)
        : null;

    final nameController = TextEditingController(text: item?.name ?? '');
    final qtyController = TextEditingController(
      text: (item?.quantityValue ?? 0) > 0
          ? (item!.quantityValue % 1 == 0
                ? item.quantityValue.toInt().toString()
                : item.quantityValue.toString().replaceAll('.', ','))
          : '',
    );
    final priceController = TextEditingController(
      text: (item?.priceValue ?? 0) > 0
          ? (item!.priceValue.toStringAsFixed(2).replaceAll('.', ','))
          : '0,00',
    );

    String qUnit = item?.quantityUnit ?? 'un';
    String pUnit = item?.priceUnit ?? 'un';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          double calculatePreviewTotal() {
            final qText = qtyController.text.trim().replaceAll(',', '.');
            final pText = priceController.text.trim().replaceAll(
              RegExp(r'\D'),
              '',
            );

            final q = double.tryParse(qText) ?? 0.0;
            final p = (double.tryParse(pText) ?? 0.0) / 100;

            return ShoppingItem.calculateTotal(q, qUnit, p, pUnit);
          }

          final previewTotal = calculatePreviewTotal();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Editar Item' : 'Novo Item',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nome do item',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.shopping_basket_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 10),

                // Quantity Group
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: qtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Quantidade',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.scale_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: qUnit,
                        decoration: const InputDecoration(
                          labelText: 'Und',
                          border: OutlineInputBorder(),
                        ),
                        items: ShoppingItem.units
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => qUnit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price Group
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        inputFormatters: [_CurrencyInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Preço',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: pUnit,
                        decoration: const InputDecoration(
                          labelText: 'por',
                          border: OutlineInputBorder(),
                        ),
                        items: ShoppingItem.units
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => pUnit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Preview total
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total do Item:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'R\$ ${previewTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: previewTotal > 0
                              ? const Color(0xFF6342E8)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (previewTotal == 0 &&
                    qtyController.text.isNotEmpty &&
                    priceController.text.isNotEmpty &&
                    qUnit != pUnit)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Unidades incompatíveis para cálculo',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final qtyText = qtyController.text.trim().replaceAll(
                      ',',
                      '.',
                    );
                    final prcText = priceController.text.trim().replaceAll(
                      RegExp(r'\D'),
                      '',
                    );

                    final qVal = double.tryParse(qtyText) ?? 0.0;
                    final pVal = (double.tryParse(prcText) ?? 0.0) / 100;
                    final total = ShoppingItem.calculateTotal(
                      qVal,
                      qUnit,
                      pVal,
                      pUnit,
                    );

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('O nome do item não pode estar vazio'),
                        ),
                      );
                      return;
                    }

                    if (isEditing) {
                      controller.editItem(
                        itemId,
                        name: name,
                        quantityValue: qVal,
                        quantityUnit: qUnit,
                        priceValue: pVal,
                        priceUnit: pUnit,
                        totalValue: total,
                      );
                    } else {
                      controller.addItem(
                        name,
                        categoryId,
                        quantityValue: qVal,
                        quantityUnit: qUnit,
                        priceValue: pVal,
                        priceUnit: pUnit,
                        totalValue: total,
                      );
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6342E8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Salvar Alterações' : 'Adicionar Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shared category picker used for Move/Copy operations
  void _showCategoryPicker(
    BuildContext context,
    Function(String? categoryId) onSelected,
  ) {
    final controller = context.read<ShoppingListController>();
    final categories = <dynamic>[];
    final sem = controller.semCategoria;
    if (sem != null) categories.add(sem);
    categories.addAll(controller.categories);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolha a categoria'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ListTile(
                leading: CircleAvatar(backgroundColor: cat.color, radius: 10),
                title: Text(cat.name),
                onTap: () {
                  Navigator.of(context).pop();
                  onSelected(cat.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Exibe confirmação antes de deletar
  void _confirmDelete(
    BuildContext context,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

/// Formata a entrada de texto como moeda (0,00)
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Mantém apenas dígitos
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(
        text: '0,00',
        selection: const TextSelection.collapsed(offset: 4),
      );
    }

    // Converte para double (centavos)
    final double value = double.parse(digits) / 100;

    // Formata com vírgula e 2 casas decimais
    final String formatted = value.toStringAsFixed(2).replaceAll('.', ',');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
