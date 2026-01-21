import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/shopping_list.dart';
import '../models/category.dart' as models;
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
  List<models.Category> _categories = [];
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
        _categories = data['categories'] as List<models.Category>;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalhes da Compra'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // "Supermarket Invoice" Style Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _list!.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  if (_list!.purchaseLocation != null &&
                      _list!.purchaseLocation!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _list!.purchaseLocation!,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: Color(0xFFE2E8F0)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pago',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        totalSpentFormatted,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F3D81),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Items List
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Itens da Lista',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildCategoriesAndItems(),
              ],
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  foregroundColor: const Color(0xFF64748B),
                ),
                child: const Text(
                  'Fechar Detalhes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoriesAndItems() {
    final widgets = <Widget>[];

    // Combine all relevant categories (those that have items in this list)
    final listCategories = _categories
        .where((cat) => _items.any((item) => item.categoryId == cat.id))
        .toList();

    // Also check for "Sem Categoria"
    final hasNoCategoryItems = _items.any(
      (item) => item.categoryId == null || item.categoryId == 'sem-categoria',
    );

    for (final cat in listCategories) {
      widgets.add(_buildCategoryHeader(cat.name, cat.colorValue));
      final catItems = _items
          .where((item) => item.categoryId == cat.id)
          .toList();
      for (final item in catItems) {
        widgets.add(_buildItemRow(item));
      }
      widgets.add(const SizedBox(height: 16));
    }

    if (hasNoCategoryItems) {
      widgets.add(_buildCategoryHeader('Sem Categoria', null));
      final catItems = _items
          .where(
            (item) =>
                item.categoryId == null || item.categoryId == 'sem-categoria',
          )
          .toList();
      for (final item in catItems) {
        widgets.add(_buildItemRow(item));
      }
    }

    return widgets;
  }

  Widget _buildCategoryHeader(String name, int? colorValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: colorValue != null ? Color(colorValue) : Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(ShoppingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            item.isChecked ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: item.isChecked
                ? const Color(0xFF10B981)
                : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                    decoration: item.isChecked
                        ? null
                        : TextDecoration.lineThrough,
                    decorationColor: Colors.grey,
                  ),
                ),
                if (item.quantityValue > 0)
                  Text(
                    '${item.quantityValue % 1 == 0 ? item.quantityValue.toInt() : item.quantityValue} ${item.quantityUnit}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
          if (item.totalValue > 0)
            Text(
              'R\$ ${item.totalValue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
        ],
      ),
    );
  }
}
