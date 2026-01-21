import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/shopping_list_controller.dart';
import 'shopping_list_screen.dart';

/// Tela inicial que exibe todas as listas de compras
///
/// Permite:
/// - Visualizar todas as listas criadas
/// - Criar novas listas
/// - Navegar para uma lista específica
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Listas'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Consumer<ShoppingListController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mensagem de boas-vindas
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Olá! Aqui estão suas listas de compras 🛒',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                ),
              ),

              // Lista de listas de compras
              Expanded(
                child: controller.shoppingLists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma lista criada ainda',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toque no botão + para criar sua primeira lista',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: controller.shoppingLists.length,
                        itemBuilder: (context, index) {
                          final list = controller.shoppingLists[index];
                          final isActive = list.id == controller.activeListId;

                          return Card(
                            elevation: isActive ? 4 : 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isActive
                                  ? const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    )
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.blue.shade50
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.shopping_basket,
                                  color: isActive ? Colors.blue : Colors.grey,
                                ),
                              ),
                              title: Text(
                                list.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                'Criada ${_formatDate(list.createdAt)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                              onTap: () =>
                                  _openList(context, controller, list.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'hoje';
    } else if (difference.inDays == 1) {
      return 'ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _openList(
    BuildContext context,
    ShoppingListController controller,
    String listId,
  ) async {
    // Set active list and load its data
    await controller.setActiveList(listId);

    // Navigate to shopping list screen
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ShoppingListScreen()),
      );
    }
  }
}
