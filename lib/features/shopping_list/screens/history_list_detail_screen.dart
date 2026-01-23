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
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_list == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7FB),
        body: Center(child: Text('Lista não encontrada')),
      );
    }

    final dateStr = _list!.purchaseDate != null
        ? DateFormat('dd/MM/yyyy').format(_list!.purchaseDate!)
        : DateFormat('dd/MM/yyyy').format(_list!.createdAt);

    final totalSpentFormatted = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
    ).format(_list!.totalSpent ?? 0.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              child: Center(
                child: _buildReceiptCard(dateStr, totalSpentFormatted),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomActionBar(dateStr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(String dateStr, String totalSpentFormatted) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 28,
              color: Color(0xFF0F3D81),
            ),
          ),
          const SizedBox(height: 16),

          // Title and Subtitle
          Text(
            _list!.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Compra realizada com sucesso',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          // Purchase Info Rows
          _buildInfoRow(
            Icons.location_on_outlined,
            'Local:',
            _list!.purchaseLocation ?? 'Não informado',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.calendar_today_outlined, 'Data:', dateStr),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.shopping_cart_outlined,
            'Itens:',
            '${_items.where((i) => i.isChecked).length} produtos',
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Items List Section
          ..._items
              .where((i) => i.isChecked)
              .map((item) => _buildItemRow(item))
              .toList(),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Totals Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                totalSpentFormatted,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F3D81),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Footer Note
          Text(
            'COMPRA SALVA • ${dateStr.toUpperCase()}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(ShoppingItem item) {
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${item.quantityValue % 1 == 0 ? item.quantityValue.toInt() : item.quantityValue} ${item.quantityUnit}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(String dateStr) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB).withOpacity(0.95),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Compartilhar',
              icon: Icons.ios_share_rounded,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              label: 'Baixar',
              icon: Icons.download_rounded,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
