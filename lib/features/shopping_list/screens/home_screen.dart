import 'package:checklist_app/features/shopping_list/screens/settings_screen.dart';
import 'package:checklist_app/features/shopping_list/screens/send_file_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
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

    final totalItems = ShoppingItem.getTotalCount(items);
    final checkedItems = ShoppingItem.getCompletedCount(items);
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
                  // 1. Dashboard Card
                  _buildDashboardCard(
                    context,
                    controller,
                    colorScheme,
                    textTheme,
                  ),

                  // 3. Favoritas
                  if (favoriteLists.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Favoritas'),
                    SizedBox(
                      height: 155,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: favoriteLists.length,
                        itemBuilder: (context, index) {
                          final list = favoriteLists[index];
                          final metadata = _getMetadataFor(list, controller);
                          return Container(
                            width: 200,
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
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: incompleteLists.length,
                        itemBuilder: (context, index) {
                          final list = incompleteLists[index];
                          final metadata = _getMetadataFor(list, controller);
                          return Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 16),
                            child: _buildListCard(context, list, metadata),
                          );
                        },
                      ),
                    ),

                  // 5. Completas
                  if (completeLists.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Listas completas'),
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: completeLists.length,
                        itemBuilder: (context, index) {
                          final list = completeLists[index];
                          final metadata = _getMetadataFor(list, controller);
                          return Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 16),
                            child: _buildListCard(context, list, metadata),
                          );
                        },
                      ),
                    ),
                  ],

                  // 6. Upload Section
                  _buildUploadSection(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    ShoppingListController controller,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final prevMonth = now.month == 1
        ? DateTime(now.year - 1, 12)
        : DateTime(now.year, now.month - 1);

    final completedLists = controller.completedLists;

    double getSpending(DateTime month) {
      return completedLists
          .where((l) {
            final date = l.purchaseDate ?? l.createdAt;
            return date.year == month.year && date.month == month.month;
          })
          .fold(0.0, (sum, l) => sum + (l.totalSpent ?? 0.0));
    }

    int getPurchases(DateTime month) {
      return completedLists.where((l) {
        final date = l.purchaseDate ?? l.createdAt;
        return date.year == month.year && date.month == month.month;
      }).length;
    }

    final currentSpending = getSpending(currentMonth);
    final prevSpending = getSpending(prevMonth);
    final currentPurchases = getPurchases(currentMonth);
    final prevPurchases = getPurchases(prevMonth);
    final spendingDelta = (currentSpending - prevSpending).abs();
    final isSpendingUp = currentSpending > prevSpending;
    final isSpendingDown = currentSpending < prevSpending;

    final isPurchasesUp = currentPurchases > prevPurchases;
    final isPurchasesDown = currentPurchases < prevPurchases;

    // "Últimas acessadas" logic: Most recently modified
    final activeLists = controller.activeLists;
    final recentLists = activeLists.toList()
      ..sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
    final displayRecent = recentLists.take(2).toList();

    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary, // Dark blue from theme
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. User header row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: const AssetImage(
                  'assets/Images/ProfilePicture.png',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Olá, Vinícius',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                icon: const Icon(Icons.settings, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Two-column content area
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column A: Monthly summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM d, y', 'pt_BR').format(now),
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RESUMO DO MÊS',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(currentSpending),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Indicator: Purchases
                    Row(
                      children: [
                        Icon(
                          isPurchasesUp
                              ? Icons.arrow_upward
                              : isPurchasesDown
                              ? Icons.arrow_downward
                              : Icons.remove,
                          size: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$currentPurchases compras',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Indicator: Spending delta
                    Row(
                      children: [
                        Icon(
                          isSpendingUp
                              ? Icons.arrow_upward
                              : isSpendingDown
                              ? Icons.arrow_downward
                              : Icons.remove,
                          size: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isSpendingUp
                              ? '↑'
                              : isSpendingDown
                              ? '↓'
                              : ''} ${currencyFormat.format(spendingDelta)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Column B: Últimas acessadas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ÚLTIMAS ACESSADAS',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (displayRecent.isEmpty)
                      Text(
                        'Nenhuma lista ativa',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.4),
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      ...displayRecent.map((list) {
                        final metadata = _getMetadataFor(list, controller);
                        final progress = metadata['progress'] as double;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () =>
                                _openList(context, controller, list.id),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            value: progress,
                                            strokeWidth: 2,
                                            backgroundColor: Colors.white
                                                .withOpacity(0.1),
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(Color(0xFF00BFA5)),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      list.name,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onUploadTap(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SendFileScreen()));
  }

  Widget _buildUploadSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: InkWell(
        onTap: () => _onUploadTap(context),
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: colorScheme.primary.withOpacity(0.3),
            strokeWidth: 2,
            gap: 6,
            dash: 6,
            radius: 20,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Icon Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.upload_file_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faça upload das suas listas',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PDF, DOC, DOCX, Excel',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
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

  // Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
  //   return Center(
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Icon(
  //           Icons.shopping_cart_outlined,
  //           size: 80,
  //           color: colorScheme.onSurface.withOpacity(0.1),
  //         ),
  //         const SizedBox(height: 16),
  //         Text(
  //           'Nenhuma lista ativa',
  //           style: textTheme.titleLarge?.copyWith(
  //             color: colorScheme.onSurface.withOpacity(0.5),
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           'Toque no botão + para criar sua próxima lista',
  //           style: textTheme.bodyMedium?.copyWith(
  //             color: colorScheme.onSurface.withOpacity(0.4),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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

    return Stack(
      children: [
        Container(
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
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ring - CircularProgressIndicator
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 3,
                                  backgroundColor: colorScheme.primaryContainer
                                      .withOpacity(0.3),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF00BFA5),
                                      ),
                                ),
                              ),

                              // Center icon
                              CircleAvatar(
                                backgroundColor: colorScheme.secondary
                                    .withValues(alpha: 0.15),
                                backgroundImage: AssetImage(
                                  'assets/Icons/Default_list.png',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                              Text(
                                list.name,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF263238),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF00BFA5).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            formattedTotal,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Favorite icon positioned in top-right corner
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () {
              context.read<ShoppingListController>().toggleFavorite(list.id);
            },
            borderRadius: BorderRadius.circular(20),
            child: Icon(
              Icons.favorite_rounded,
              color: list.isFavorite
                  ? Colors.red
                  : Colors.grey.withOpacity(0.5),
              size: 22,
            ),
          ),
        ),
      ],
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

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.dash = 5.0,
    this.radius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final Path dashedPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gap != gap ||
      oldDelegate.dash != dash ||
      oldDelegate.radius != radius;
}
