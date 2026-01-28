import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:checklist_app/main.dart';
import '../state/shopping_list_controller.dart';
import 'finalize_list_screen.dart';
import '../widgets/category_section.dart';
import '../widgets/shopping_list_summary_card.dart';
import '../widgets/quantity_stepper.dart';
import '../models/shopping_item.dart';

/// Tela principal da lista de compras
///
/// Exibe:
/// - Seção "Sem categoria" (sempre visível)
/// - Todas as categorias criadas pelo usuário
/// - FAB para adicionar nova categoria
class ShoppingListScreen extends StatefulWidget {
  final String? focusCategoryId;
  final String? focusItemId;

  const ShoppingListScreen({super.key, this.focusCategoryId, this.focusItemId});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final Map<String, GlobalKey> _categoryKeys = {};
  final Map<String, GlobalKey> _itemKeys = {};
  bool _hasScrolledToFocus = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusCategoryId != null || widget.focusItemId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocus());
    }
  }

  void _scrollToFocus() {
    if (!mounted || _hasScrolledToFocus) return;

    final controller = context.read<ShoppingListController>();
    String? targetCategoryId = widget.focusCategoryId;
    String? targetItemId = widget.focusItemId;

    if (targetItemId != null) {
      final item = controller.allItems.firstWhere(
        (i) => i.id == targetItemId,
        orElse: () => ShoppingItem(id: '', name: '', createdAt: DateTime.now()),
      );
      if (item.id.isNotEmpty) {
        targetCategoryId = item.categoryId;
        // Ensure category is expanded
        if (targetCategoryId != null &&
            controller.isCategoryCollapsed(targetCategoryId)) {
          controller.toggleCategoryCollapse(targetCategoryId);
        }
      }
    } else if (targetCategoryId != null) {
      // Ensure category is expanded
      if (controller.isCategoryCollapsed(targetCategoryId)) {
        controller.toggleCategoryCollapse(targetCategoryId);
      }
    }

    // Wait for expansion animation/layout
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final targetKey = targetItemId != null
          ? _itemKeys[targetItemId]
          : _categoryKeys[targetCategoryId];

      if (targetKey != null && targetKey.currentContext != null) {
        Scrollable.ensureVisible(
          targetKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
        setState(() => _hasScrolledToFocus = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                                    key: _categoryKeys.putIfAbsent(
                                      'sem-categoria',
                                      () => GlobalKey(),
                                    ),
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
                                    itemKeys: _itemKeys,
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
                                      key: _categoryKeys.putIfAbsent(
                                        category.id,
                                        () => GlobalKey(),
                                      ),
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
                                      itemKeys: _itemKeys,
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
                                  onPressed: controller.checkedItemsCount > 0
                                      ? () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const FinalizeListScreen(),
                                            ),
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme
                                        .secondary, // Accent Turquoise for CTA
                                    foregroundColor:
                                        theme.brightness == Brightness.light
                                        ? Colors.white
                                        : colorScheme.onSecondary,
                                    disabledBackgroundColor: colorScheme
                                        .onSurface
                                        .withOpacity(0.05),
                                    disabledForegroundColor: colorScheme
                                        .onSurface
                                        .withOpacity(0.38),
                                    minimumSize: const Size(
                                      double.infinity,
                                      56,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 4,
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
            backgroundColor:
                colorScheme.primary, // Dark Blue/Turquoise for primary button
            foregroundColor: theme.brightness == Brightness.light
                ? Colors.white
                : colorScheme.onPrimary,
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
        persist: false,
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () {
            controller.restoreItem(item);
          },
          //onPressed: () => controller.restoreItem(item),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = context.read<ShoppingListController>();
    final isEditing = itemId != null;

    final item = isEditing
        ? controller.allItems.firstWhere((i) => i.id == itemId)
        : null;

    final nameController = TextEditingController(text: item?.name ?? '');
    int quantity = (item?.quantityValue ?? 0) > 0
        ? item!.quantityValue.toInt()
        : 1;
    final priceController = TextEditingController(
      text: (item?.priceValue ?? 0) > 0
          ? (item!.priceValue.toStringAsFixed(2).replaceAll('.', ','))
          : '0,00',
    );

    String qUnit = item?.quantityUnit ?? 'und';
    String pUnit = item?.priceUnit ?? 'und';

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          double calculatePreviewTotal() {
            final q = quantity.toDouble();
            final pText = priceController.text.trim().replaceAll(
              RegExp(r'\D'),
              '',
            );

            final p = (double.tryParse(pText) ?? 0.0) / 100;

            return ShoppingItem.calculateTotal(q, qUnit, p, pUnit);
          }

          final previewTotal = calculatePreviewTotal();

          // Helper para criar o container estilizado (mesmo estilo do QuantityStepper)
          Widget buildStyledInput({
            required Widget child,
            String? label,
            IconData? prefixIcon,
          }) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null) ...[
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: prefixIcon != null ? 0 : 16,
                  ),
                  child: Row(
                    children: [
                      if (prefixIcon != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Icon(
                            prefixIcon,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Form(
              key: formKey,
              child: ListView(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Editar Item' : 'Novo Item',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  buildStyledInput(
                    label: 'Nome do item',
                    prefixIcon: Icons.shopping_basket_outlined,
                    child: TextFormField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Arroz, Feijão...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'O nome do item não pode ser vazio.';
                        }
                        return null;
                      },
                    ),
                  ),

                  // Quantity Group
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantidade',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            QuantityStepper(
                              value: quantity,
                              onChanged: (newValue) {
                                setState(() {
                                  quantity = newValue;
                                });
                              },
                              min: 1,
                              max: 999,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: buildStyledInput(
                          label: 'Unid.',
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: qUnit,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              items: ShoppingItem.units
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    qUnit = val;
                                    pUnit = val;
                                  });
                                }
                              },
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price Group
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: buildStyledInput(
                          label: 'Preço',
                          prefixIcon: Icons.attach_money_rounded,
                          child: TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            inputFormatters: [_CurrencyInputFormatter()],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: buildStyledInput(
                          label: 'por',
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: pUnit,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              items: ShoppingItem.units
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => pUnit = val);
                              },
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Preview total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total do Item:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'R\$ ${previewTotal.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: previewTotal > 0
                                ? colorScheme.primary
                                : colorScheme.onSurface.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (previewTotal == 0 &&
                      quantity > 0 &&
                      priceController.text.isNotEmpty &&
                      qUnit != pUnit)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Unidades incompatíveis para cálculo',
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final qVal = quantity.toDouble();
                      final prcText = priceController.text.trim().replaceAll(
                        RegExp(r'\D'),
                        '',
                      );

                      final pVal = (double.tryParse(prcText) ?? 0.0) / 100;
                      final total = ShoppingItem.calculateTotal(
                        qVal,
                        qUnit,
                        pVal,
                        pUnit,
                      );

                      if (!formKey.currentState!.validate()) return;

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
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: theme.brightness == Brightness.light
                          ? Colors.white
                          : colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
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
    final theme = Theme.of(context);
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
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
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
