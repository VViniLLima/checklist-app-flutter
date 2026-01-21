import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/shopping_list_controller.dart';

/// Widget compacto do cartão de resumo da lista de compras
/// Optimizado para telas pequenas com layout de duas linhas
class ShoppingListSummaryCard extends StatelessWidget {
  final VoidCallback? onRename;
  final VoidCallback? onBack;

  const ShoppingListSummaryCard({super.key, this.onRename, this.onBack});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ShoppingListController>();
    final listName = controller.activeList?.name ?? 'Lista de Compras';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6342E8), Color(0xFF4A68FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6342E8).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 0: List Name and Actions
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: onBack,
                ),
              if (onBack != null) const SizedBox(width: 12),
              Expanded(
                child: Text(
                  listName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onRename != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                  onPressed: onRename,
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 1: Ratio and Progress
          Row(
            children: [
              Text(
                '${controller.checkedItemsCount}/${controller.totalItemsCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: controller.progressRatio,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Budget Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('ESTIMADO', controller.estimatedTotal),
              _buildMetric('NO CARRINHO', controller.cartTotal, isBold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, double value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: label == 'ESTIMADO'
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          'R\$ ${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
