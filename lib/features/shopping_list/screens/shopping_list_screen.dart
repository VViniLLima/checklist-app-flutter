import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/shopping_list_controller.dart';
import '../widgets/category_section.dart';

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
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ShoppingListController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Seção "Sem categoria" (sempre no topo)
              CategorySection(
                category: null,
                items: controller.getItemsByCategory(null),
                isCollapsed: false, // "Sem categoria" nunca colapsa
                onToggleCollapse: () {}, // Não faz nada
                onAddItem: () => _showAddItemDialog(context, null),
                onToggleItemCheck: controller.toggleItemCheck,
                onDeleteItem: (itemId) => _confirmDelete(
                  context,
                  'Deseja remover este item?',
                  () => controller.removeItem(itemId),
                ),
              ),

              // Categorias criadas
              ...controller.categories.map((category) {
                final items = controller.getItemsByCategory(category.id);
                final isCollapsed = controller.isCategoryCollapsed(category.id);

                return CategorySection(
                  key: ValueKey(category.id),
                  category: category,
                  items: items,
                  isCollapsed: isCollapsed,
                  onToggleCollapse: () =>
                      controller.toggleCategoryCollapse(category.id),
                  onAddItem: () => _showAddItemDialog(context, category.id),
                  onToggleItemCheck: controller.toggleItemCheck,
                  onDeleteItem: (itemId) => _confirmDelete(
                    context,
                    'Deseja remover este item?',
                    () => controller.removeItem(itemId),
                  ),
                );
              }),
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
              controller.addCategory(value.trim());
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
              controller.addCategory(name);
              Navigator.of(context).pop();
            },
            child: const Text('Adicionar'),
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
