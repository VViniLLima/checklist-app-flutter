import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import '../state/shopping_list_controller.dart';

class HistoryListDetailScreen extends StatefulWidget {
  final String listId;

  const HistoryListDetailScreen({super.key, required this.listId});

  @override
  State<HistoryListDetailScreen> createState() =>
      _HistoryListDetailScreenState();
}

class _HistoryListDetailScreenState extends State<HistoryListDetailScreen> {
  bool _isLoading = true;
  ShoppingList? _list;
  List<ShoppingItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final controller = context.read<ShoppingListController>();
    final list = controller.shoppingLists.firstWhere(
      (l) => l.id == widget.listId,
    );
    final data = await controller.getHistoryListData(widget.listId);

    if (mounted) {
      setState(() {
        _list = list;
        _items = data['items'] as List<ShoppingItem>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_list == null) {
      return const Scaffold(body: Center(child: Text('Lista não encontrada')));
    }

    final dateStr = _list!.purchaseDate != null
        ? DateFormat('dd/MM/yyyy').format(_list!.purchaseDate!)
        : DateFormat('dd/MM/yyyy').format(_list!.createdAt);

    final totalSpentFormatted = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
    ).format(_list!.totalSpent ?? 0.0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              child: Center(
                child: _buildReceiptCard(context, dateStr, totalSpentFormatted),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomActionBar(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(
    BuildContext context,
    String dateStr,
    String totalSpentFormatted,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.light ? 0.04 : 0.2,
            ),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Icon Badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 28,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Title and Subtitle
          Text(
            _list!.name,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Compra realizada com sucesso',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),

          // Purchase Info Rows
          _buildInfoRow(
            context,
            Icons.location_on_outlined,
            'Local:',
            _list!.purchaseLocation ?? 'Não informado',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            context,
            Icons.calendar_today_outlined,
            'Data:',
            dateStr,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            context,
            Icons.shopping_cart_outlined,
            'Itens:',
            '${ShoppingItem.getCompletedCount(_items)} produtos',
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(
              height: 1,
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),

          // Items List Section
          ..._items
              .where((i) => i.isChecked)
              .map((item) => _buildItemRow(context, item))
              .toList(),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(
              height: 1,
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),

          // Totals Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                totalSpentFormatted,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Footer Note
          Text(
            'COMPRA SALVA • ${dateStr.toUpperCase()}',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withOpacity(0.3),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurface.withOpacity(0.4)),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(BuildContext context, ShoppingItem item) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${item.quantityValue % 1 == 0 ? item.quantityValue.toInt() : item.quantityValue} ${item.quantityUnit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.totalValue > 0
                ? NumberFormat.currency(
                    locale: 'pt_BR',
                    symbol: r'R$',
                  ).format(item.totalValue)
                : '-',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              label: 'Compartilhar',
              icon: Icons.ios_share_rounded,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context,
              label: 'Baixar',
              icon: Icons.download_rounded,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
