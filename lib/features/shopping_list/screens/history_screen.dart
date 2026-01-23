import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/shopping_list_controller.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import 'history_list_detail_screen.dart';

enum HistoryFilter { all, thisMonth, last3Months }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _currentFilter = HistoryFilter.all;
  final Map<String, int> _listItemsCount = {};

  @override
  void initState() {
    super.initState();
    _loadAllItemsCounts();
  }

  Future<void> _loadAllItemsCounts() async {
    final controller = context.read<ShoppingListController>();
    for (final list in controller.completedLists) {
      if (!_listItemsCount.containsKey(list.id)) {
        final data = await controller.getHistoryListData(list.id);
        final items = data['items'] as List<ShoppingItem>;
        if (mounted) {
          setState(() {
            _listItemsCount[list.id] = items.length;
          });
        }
      }
    }
  }

  List<ShoppingList> _getFilteredLists(List<ShoppingList> allLists) {
    final now = DateTime.now();
    switch (_currentFilter) {
      case HistoryFilter.all:
        return allLists;
      case HistoryFilter.thisMonth:
        return allLists.where((l) {
          final date = l.purchaseDate ?? l.createdAt;
          return date.month == now.month && date.year == now.year;
        }).toList();
      case HistoryFilter.last3Months:
        return allLists.where((l) {
          final date = l.purchaseDate ?? l.createdAt;
          final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
          return date.isAfter(threeMonthsAgo);
        }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Consumer<ShoppingListController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final filteredLists = _getFilteredLists(controller.completedLists);
        final totalSpent = filteredLists.fold(
          0.0,
          (sum, l) => sum + (l.totalSpent ?? 0.0),
        );
        final avgSpent = filteredLists.isEmpty
            ? 0.0
            : totalSpent / filteredLists.length;

        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pinned Summary Card with Safe Area
              Container(
                color: theme.colorScheme.primary,
                child: SafeArea(
                  bottom: false,
                  child: _buildSummaryCard(
                    context,
                    totalSpent,
                    filteredLists.length,
                    avgSpent,
                  ),
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    bottom: 100,
                  ), // Space for bottom nav
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterRow(context),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Compras realizadas',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (filteredLists.isEmpty)
                        _buildEmptyState(context)
                      else
                        ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredLists.length,
                          itemBuilder: (context, index) {
                            final list = filteredLists[index];
                            return _buildHistoryCard(context, list);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double totalSpent,
    int count,
    double average,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', 'pt_BR').format(now);
    final formattedTotal = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
    ).format(totalSpent);
    final formattedAverage = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
    ).format(average);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthName.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'TOTAL GASTO',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formattedTotal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildChip('$count compras'),
              const SizedBox(width: 8),
              _buildChip('Média $formattedAverage'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildFilterButton('Todos', HistoryFilter.all),
            _buildFilterButton('Este mês', HistoryFilter.thisMonth),
            _buildFilterButton('Últimos 3 meses', HistoryFilter.last3Months),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, HistoryFilter filter) {
    final isSelected = _currentFilter == filter;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ShoppingList list) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final dateStr = list.purchaseDate != null
        ? DateFormat('dd/MM/yyyy').format(list.purchaseDate!)
        : DateFormat('dd/MM/yyyy').format(list.createdAt);

    final totalSpentFormatted = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
    ).format(list.totalSpent ?? 0.0);

    final itemCount = _listItemsCount[list.id] ?? 0;

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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: colorScheme.primary,
                  size: 24,
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 11,
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$itemCount itens',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    if (list.purchaseLocation?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              list.purchaseLocation!,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total', style: textTheme.bodySmall),
                  Text(
                    totalSpentFormatted,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withOpacity(0.2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma compra nesta categoria',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
