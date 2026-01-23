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
    return Consumer<ShoppingListController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF6F7FB),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final completedLists = controller.completedLists;

        if (completedLists.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFF6F7FB),
            appBar: AppBar(
              title: const Text(
                'Histórico de Compras',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma compra finalizada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: AppBar(
            title: const Text(
              'Histórico de Compras',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
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
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: InkWell(
                  onTap: () => _openHistoryDetail(context, list.id),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF0F3D81),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                list.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  if (list.purchaseLocation != null &&
                                      list.purchaseLocation!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    const Text(
                                      '•',
                                      style: TextStyle(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        list.purchaseLocation!,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF94A3B8),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F3D81),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFFCBD5E1),
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
