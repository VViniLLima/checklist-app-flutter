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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Listas'),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Lista de listas de compras
              Expanded(
                child: controller.activeLists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 80,
                              color: colorScheme.onSurface.withOpacity(0.1),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma lista ativa',
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toque no botão + para criar sua próxima lista',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 120,
                        ),
                        itemCount: controller.activeLists.length,
                        itemBuilder: (context, index) {
                          final list = controller.activeLists[index];
                          final isActive = list.id == controller.activeListId;

                          return Card(
                            elevation: isActive ? 4 : 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isActive
                                    ? colorScheme.primary
                                    : colorScheme.outline.withOpacity(0.1),
                                width: isActive ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.shopping_basket_rounded,
                                  color: isActive
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                              title: Text(
                                list.name,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Criada ${_formatDate(list.createdAt)}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: colorScheme.onSurface.withOpacity(0.3),
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
