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
import 'package:intl/intl.dart';
import '../models/shopping_item.dart';
import '../models/shopping_list.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final Map<String, Map<String, dynamic>> _listMetadata = {};
  bool _isMetadataLoading = false;
  Offset _tapPosition = Offset.zero;

  void _getTapPosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  @override
  void initState() {
    super.initState();
    _loadAllMetadata();
  }

  Future<void> _loadAllMetadata({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isMetadataLoading = true);

    final controller = context.read<ShoppingListController>();
    for (final list in controller.activeLists) {
      if (forceRefresh || !_listMetadata.containsKey(list.id)) {
        await _loadMetadataForList(list.id);
      }
    }

    if (mounted) {
      setState(() => _isMetadataLoading = false);
    }
  }

  Future<void> _loadMetadataForList(String listId) async {
    final controller = context.read<ShoppingListController>();
    final data = await controller.getHistoryListData(listId);
    final items = data['items'] as List<ShoppingItem>;

    final totalItems = items.length;
    final checkedItems = items.where((i) => i.isChecked).length;
    final progress = totalItems == 0 ? 0.0 : checkedItems / totalItems;
    final estimatedTotal = items.fold(
      0.0,
      (sum, item) => sum + item.totalValue,
    );

    if (mounted) {
      setState(() {
        _listMetadata[listId] = {
          'totalItems': totalItems,
          'checkedItems': checkedItems,
          'progress': progress,
          'estimatedTotal': estimatedTotal,
        };
      });
    }
  }

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

          final activeLists = controller.activeLists;

          // Trigger metadata load if new lists appear
          if (activeLists.any((l) => !_listMetadata.containsKey(l.id)) &&
              !_isMetadataLoading) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _loadAllMetadata(),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Olá! Aqui estão suas listas de compras 🛒',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: activeLists.isEmpty
                    ? _buildEmptyState(colorScheme, textTheme)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        itemCount: activeLists.length,
                        itemBuilder: (context, index) {
                          final list = activeLists[index];

                          // Use live data from controller if this is the active list
                          final Map<String, dynamic> metadata;
                          if (list.id == controller.activeListId) {
                            metadata = {
                              'totalItems': controller.totalItemsCount,
                              'checkedItems': controller.checkedItemsCount,
                              'progress': controller.progressRatio,
                              'estimatedTotal': controller.estimatedTotal,
                              'isFavorite':
                                  _listMetadata[list.id]?['isFavorite'] ??
                                  false,
                            };
                          } else {
                            metadata =
                                _listMetadata[list.id] ??
                                {
                                  'totalItems': 0,
                                  'checkedItems': 0,
                                  'progress': 0.0,
                                  'estimatedTotal': 0.0,
                                  'isFavorite': false,
                                };
                          }

                          return _buildListCard(context, list, metadata);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
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
    );
  }

  Widget _buildListCard(
    BuildContext context,
    ShoppingList list,
    Map<String, dynamic> metadata,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final totalItems = metadata['totalItems'] as int;
    final checkedItems = metadata['checkedItems'] as int;
    final progress = metadata['progress'] as double;
    final estimatedTotal = metadata['estimatedTotal'] as double;

    final formattedTotal = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
    ).format(estimatedTotal);

    final dateStr = DateFormat('d MMM', 'pt_BR').format(list.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onTapDown: _getTapPosition,
        child: InkWell(
          onTap: () => _openList(
            context,
            context.read<ShoppingListController>(),
            list.id,
          ),
          onLongPress: () => _showContextMenu(context, list),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Icon, Name, Date, Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1), // Light green-ish
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_basket_rounded,
                        color: Color(0xFF00897B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            list.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF263238),
                            ),
                          ),
                          Text(
                            dateStr,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (progress == 1.0 && totalItems > 0)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF26A69A),
                            size: 22,
                          ),
                        if (progress == 1.0 && totalItems > 0)
                          const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              final current =
                                  _listMetadata[list.id]?['isFavorite'] ??
                                  false;
                              _listMetadata[list.id] = {
                                ...(_listMetadata[list.id] ?? {}),
                                'isFavorite': !current,
                              };
                            });
                          },
                          child: Icon(
                            Icons.favorite_rounded,
                            color: (metadata['isFavorite'] ?? false)
                                ? Colors.red
                                : Colors.grey.withOpacity(0.5),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Info Row: Items count and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$checkedItems/$totalItems',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      formattedTotal,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF263238),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: colorScheme.primaryContainer.withOpacity(
                      0.3,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00BFA5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, ShoppingList list) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        _tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(
                Icons.copy_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Text('Duplicar'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Text('Editar'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Excluir',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openList(
    BuildContext context,
    ShoppingListController controller,
    String listId,
  ) async {
    await controller.setActiveList(listId);
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ShoppingListScreen()),
      );
      // Refresh all metadata when coming back from the list
      _loadAllMetadata(forceRefresh: true);
    }
  }
}
