import 'package:flutter/material.dart';
import 'nav_bar_painter.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onCenterTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // According to 60-30-10 rule:
    // 30% Primary (Dark Blue) for selected navigation items
    // 10% Accent (Turquoise) for CTAs (Center Button)

    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurface.withOpacity(0.4);
    final centerButtonColor = colorScheme.secondary; // Accent color

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = 85.0 + bottomPadding;

    return SizedBox(
      height: navBarHeight,
      child: Stack(
        children: [
          // Background with painter
          Positioned.fill(
            child: CustomPaint(
              painter: NavBarPainter(color: colorScheme.surface),
            ),
          ),

          // Navigation Items
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavBarItem(
                      index: 0,
                      currentIndex: currentIndex,
                      icon: Icons.home_rounded,
                      label: 'Home',
                      onTap: onTap,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                    _NavBarItem(
                      index: 1,
                      currentIndex: currentIndex,
                      icon: Icons.view_list_rounded,
                      label: 'Lists',
                      onTap: onTap,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                    const SizedBox(width: 56), // Space for center button
                    _NavBarItem(
                      index: 3,
                      currentIndex: currentIndex,
                      icon: Icons.history,
                      label: 'Histórico',
                      onTap: onTap,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                    _NavBarItem(
                      index: 4,
                      currentIndex: currentIndex,
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      onTap: onTap,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center Button
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 0),
              child: GestureDetector(
                onTap: onCenterTap,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: centerButtonColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: centerButtonColor.withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add,
                    color: theme.brightness == Brightness.light
                        ? Colors.white
                        : colorScheme.onPrimary,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final Function(int) onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _NavBarItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active indicator line
          Container(
            width: 20,
            height: 3.0,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Icon(icon, color: isActive ? activeColor : inactiveColor, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : inactiveColor,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
