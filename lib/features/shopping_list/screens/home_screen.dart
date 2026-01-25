import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/shopping_list_controller.dart';
import '../../../core/theme/theme_controller.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        final existing = _listMetadata[listId] ?? {};
        _listMetadata[listId] = {
          ...existing,
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
      backgroundColor: colorScheme.background,
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

          // Grouping logic
          final favoriteLists = activeLists.where((l) => l.isFavorite).toList();

          final incompleteLists = activeLists.where((l) {
            final metadata = _listMetadata[l.id];
            if (metadata == null)
              return true; // Assume incomplete if metadata not yet loaded
            final total = metadata['totalItems'] as int;
            final checked = metadata['checkedItems'] as int;
            return total == 0 || checked < total;
          }).toList();

          final completeLists = activeLists.where((l) {
            final metadata = _listMetadata[l.id];
            if (metadata == null) return false;
            final total = metadata['totalItems'] as int;
            final checked = metadata['checkedItems'] as int;
            return total > 0 && checked == total;
          }).toList();

          return SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Profile Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: const AssetImage(
                            'assets/Images/profilePicture.webp',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, Vinícius',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onBackground,
                              ),
                            ),
                            Text(
                              'Vamos às compras? 🛒',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Theme Toggle Button
                        Consumer<ThemeController>(
                          builder: (context, themeController, _) {
                            final isDark =
                                themeController.themeMode == ThemeMode.dark;
                            return InkWell(
                              onTap: () => themeController.toggleTheme(),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: RotationTransition(
                                        turns: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    isDark
                                        ? Icons.nightlight_round_rounded
                                        : Icons.wb_sunny_rounded,
                                    key: ValueKey(isDark),
                                    color: isDark
                                        ? const Color(0xFFFFD700)
                                        : const Color(0xFFFF8C00),
                                    size: 24,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // 2. Summary Boxes (Placeholder items)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        _buildSummaryBox(
                          context,
                          'Listas Ativas',
                          '${activeLists.length}',
                          Icons.list_alt_rounded,
                          colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        _buildSummaryBox(
                          context,
                          'Total Estimado',
                          NumberFormat.currency(
                            locale: 'pt_BR',
                            symbol: r'R$',
                          ).format(
                            activeLists.fold(
                              0.0,
                              (sum, l) =>
                                  sum +
                                  (_listMetadata[l.id]?['estimatedTotal'] ??
                                      0.0),
                            ),
                          ),
                          Icons.account_balance_wallet_rounded,
                          const Color(0xFF00BFA5),
                        ),
                      ],
                    ),
                  ),

                  // 3. Favoritas
                  if (favoriteLists.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Favoritas'),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: favoriteLists.length,
                        itemBuilder: (context, index) {
                          final list = favoriteLists[index];
                          final metadata = _getMetadataFor(list, controller);
                          return Container(
                            width: 300,
                            margin: const EdgeInsets.only(right: 16),
                            child: _buildListCard(context, list, metadata),
                          );
                        },
                      ),
                    ),
                  ],

                  // 4. Incompletas
                  _buildSectionHeader(context, 'Listas incompletas'),
                  if (incompleteLists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Nenhuma lista incompleta'),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: incompleteLists.map((list) {
                          final metadata = _getMetadataFor(list, controller);
                          return _buildListCard(context, list, metadata);
                        }).toList(),
                      ),
                    ),

                  // 5. Completas
                  if (completeLists.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Listas completas'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: completeLists.map((list) {
                          final metadata = _getMetadataFor(list, controller);
                          return _buildListCard(context, list, metadata);
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _getMetadataFor(
    ShoppingList list,
    ShoppingListController controller,
  ) {
    if (list.id == controller.activeListId) {
      return {
        'totalItems': controller.totalItemsCount,
        'checkedItems': controller.checkedItemsCount,
        'progress': controller.progressRatio,
        'estimatedTotal': controller.estimatedTotal,
        'isFavorite': list.isFavorite,
      };
    } else {
      return _listMetadata[list.id] ??
          {
            'totalItems': 0,
            'checkedItems': 0,
            'progress': 0.0,
            'estimatedTotal': 0.0,
            'isFavorite': list.isFavorite,
          };
    }
  }

  Widget _buildSummaryBox(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
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
                            context
                                .read<ShoppingListController>()
                                .toggleFavorite(list.id);
                          },
                          child: Icon(
                            Icons.favorite_rounded,
                            color: list.isFavorite
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
                    Row(
                      children: [
                        Text(
                          '$checkedItems/$totalItems',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 2,
                            backgroundColor: colorScheme.primaryContainer
                                .withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00BFA5),
                            ),
                          ),
                        ),
                      ],
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
    // Save current active list's live metadata to _listMetadata before switching
    if (controller.activeListId != null) {
      final currentId = controller.activeListId!;
      _listMetadata[currentId] = {
        ...(_listMetadata[currentId] ?? {}),
        'totalItems': controller.totalItemsCount,
        'checkedItems': controller.checkedItemsCount,
        'progress': controller.progressRatio,
        'estimatedTotal': controller.estimatedTotal,
      };
    }

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
