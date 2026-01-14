import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/shopping_list_controller.dart';
import '../widgets/category_section.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Compras'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Consumer<ShoppingListController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(10),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // "Sem categoria" fica fixa no topo para evitar confusao com itens nao categorizados.
                      CategorySection(
                        category: controller.semCategoria,
                        items: controller.getItemsByCategory('sem-categoria'),
                        isCollapsed: false, // "Sem categoria" nunca colapsa
                        onToggleCollapse: () {}, // Nao faz nada
                onAddItem: () => _showAddItemDialog(context, 'sem-categoria'),
                onEditCategory: () {}, // Placeholder - color change handled in CategoryHeader
                onToggleItemCheck: controller.toggleItemCheck,
                onEditItem: (itemId) => _showEditItemDialog(context, itemId),
                onDeleteItem: (itemId) => _confirmDelete(
                  context,
                  'Deseja remover este item?',
                  () => controller.removeItem(itemId),
                ),
                onSwipeComplete: (item) => controller.markItemChecked(item.id),
                onSwipeDelete: (item) =>
                    _handleSwipeDelete(context, controller, item),
              ),
            ],
          ),
        ),
      ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                sliver: SliverReorderableList(
                  itemCount: controller.categories.length,
                  onReorder: (oldIndex, newIndex) {
                    controller.reorderCategories(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final category = controller.categories[index];
                    final items = controller.getItemsByCategory(category.id);
                    final isCollapsed = controller.isCategoryCollapsed(category.id);

                    return Material(
                      key: ValueKey(category.id),
                      child: CategorySection(
                        category: category,
                        items: items,
                        isCollapsed: isCollapsed,
                        onToggleCollapse: () =>
                            controller.toggleCategoryCollapse(category.id),
                        onAddItem: () => _showAddItemDialog(context, category.id),
                        onEditCategory: () => _showEditCategoryDialog(
                          context,
                          category.id,
                          category.name,
                        ),
                        onToggleItemCheck: controller.toggleItemCheck,
                        onEditItem: (itemId) => _showEditItemDialog(context, itemId),
                        onDeleteItem: (itemId) => _confirmDelete(
                          context,
                          'Deseja remover este item?',
                          () => controller.removeItem(itemId),
                        ),
                        onSwipeComplete: (item) =>
                            controller.markItemChecked(item.id),
                        onSwipeDelete: (item) =>
                            _handleSwipeDelete(context, controller, item),
                        showDragHandle: true,
                        headerWrapper: (header) => ReorderableDelayedDragStartListener(
                          index: index,
                          child: header,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova Categoria'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleSwipeDelete(
    BuildContext context,
    ShoppingListController controller,
    ShoppingItem item,
  ) {
    controller.removeItem(item.id);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
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
  void _showEditCategoryDialog(BuildContext context, String categoryId, String currentName) {
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
                (cat) => cat.id != categoryId && cat.name.toLowerCase() == trimmedName.toLowerCase(),
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
                (cat) => cat.id != categoryId && cat.name.toLowerCase() == name.toLowerCase(),
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

  /// Exibe dialog para editar item existente
  void _showEditItemDialog(BuildContext context, String itemId) {
    final controller = context.read<ShoppingListController>();
    final item = controller.allItems.firstWhere((i) => i.id == itemId);
    final textController = TextEditingController(text: item.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Item'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome do item',
            hintText: 'Ex: Arroz, Feijão...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              final trimmedName = value.trim();
              // Verifica se o nome já existe na mesma categoria
              final isDuplicate = controller.allItems.any(
                (i) => i.id != itemId &&
                       i.categoryId == item.categoryId &&
                       i.name.toLowerCase() == trimmedName.toLowerCase(),
              );
              
              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Já existe um item com este nome nesta categoria'),
                  ),
                );
                return;
              }
              
              controller.editItem(itemId, trimmedName);
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
                    content: Text('O nome do item não pode estar vazio'),
                  ),
                );
                return;
              }
              
              // Verifica se o nome já existe na mesma categoria
              final isDuplicate = controller.allItems.any(
                (i) => i.id != itemId &&
                       i.categoryId == item.categoryId &&
                       i.name.toLowerCase() == name.toLowerCase(),
              );
              
              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Já existe um item com este nome nesta categoria'),
                  ),
                );
                return;
              }
              
              controller.editItem(itemId, name);
              Navigator.of(context).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  /// Exibe dialog para adicionar novo item
  void _showAddItemDialog(BuildContext context, String? categoryId) {
    final controller = context.read<ShoppingListController>();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Item'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome do item',
            hintText: 'Ex: Arroz, Feijão...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              controller.addItem(value.trim(), categoryId);
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
                    content: Text('O nome do item não pode estar vazio'),
                  ),
                );
                return;
              }
              controller.addItem(name, categoryId);
              Navigator.of(context).pop();
            },
            child: const Text('Adicionar'),
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
