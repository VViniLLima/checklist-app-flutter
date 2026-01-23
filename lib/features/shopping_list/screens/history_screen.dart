import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/shopping_list_controller.dart';
import 'history_list_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Consumer<ShoppingListController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final completedLists = controller.completedLists;

        if (completedLists.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Histórico de Compras'),
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 80,
                    color: colorScheme.onSurface.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma compra finalizada',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Histórico de Compras'),
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: false,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 100,
              top: 10,
            ),
            itemCount: completedLists.length,
            itemBuilder: (context, index) {
              final list = completedLists[index];
              final dateStr = list.purchaseDate != null
                  ? DateFormat('dd/MM/yyyy').format(list.purchaseDate!)
                  : DateFormat('dd/MM/yyyy').format(list.createdAt);

              final totalSpentFormatted = NumberFormat.currency(
                locale: 'pt_BR',
                symbol: r'R$',
              ).format(list.totalSpent ?? 0.0);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
                ),
                child: InkWell(
                  onTap: () => _openHistoryDetail(context, list.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                list.name,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    dateStr,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                  if (list.purchaseLocation != null &&
                                      list.purchaseLocation!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        color: colorScheme.outline.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        list.purchaseLocation!,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          totalSpentFormatted,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: colorScheme.onSurface.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openHistoryDetail(BuildContext context, String listId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HistoryListDetailScreen(listId: listId),
      ),
    );
  }
}
