import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium stepper-style quantity selector component with Material Design 3 styling
///
/// Features:
/// - Integer values only (1-999 range)
/// - Increment/decrement buttons with ripple effects
/// - Haptic feedback on value changes
/// - 150ms smooth animations
/// - Comprehensive accessibility support
/// - Production-ready with error handling
class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 999,
    this.enabled = true,
    this.width,
    this.margin,
  });

  /// Current quantity value
  final int value;

  /// Callback when value changes
  final ValueChanged<int> onChanged;

  /// Minimum allowed value (default: 1)
  final int min;

  /// Maximum allowed value (default: 999)
  final int max;

  /// Whether the stepper is enabled
  final bool enabled;

  /// Optional fixed width
  final double? width;

  /// Optional margin
  final EdgeInsets? margin;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  DateTime? _lastTapTime;
  static const _tapDebounceMs = 50;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _canDecrement => widget.enabled && widget.value > widget.min;
  bool get _canIncrement => widget.enabled && widget.value < widget.max;

  void _handleDecrement() {
    if (!_canDecrement) return;
    if (_isDebouncedTap()) return;

    _triggerHapticFeedback();
    _playAnimation();

    final newValue = (widget.value - 1).clamp(widget.min, widget.max);
    widget.onChanged(newValue);
  }

  void _handleIncrement() {
    if (!_canIncrement) return;
    if (_isDebouncedTap()) return;

    _triggerHapticFeedback();
    _playAnimation();

    final newValue = (widget.value + 1).clamp(widget.min, widget.max);
    widget.onChanged(newValue);
  }

  bool _isDebouncedTap() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < _tapDebounceMs) {
      return true;
    }
    _lastTapTime = now;
    return false;
  }

  void _triggerHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  void _playAnimation() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: widget.width,
      height: 48,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Semantics(
        label: 'Quantidade: ${widget.value}',
        value: widget.value.toString(),
        hint: 'Use os botões para ajustar a quantidade',
        child: Row(
          children: [
            // Decrement Button
            _StepperButton(
              icon: Icons.remove,
              onPressed: _canDecrement ? _handleDecrement : null,
              enabled: _canDecrement,
              colorScheme: colorScheme,
              semanticLabel: 'Diminuir quantidade',
              isLeft: true,
            ),

            // Divider
            Container(
              width: 1,
              height: 24,
              color: colorScheme.outline.withOpacity(0.1),
            ),

            // Center Display
            Expanded(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.value.toString(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: widget.enabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.38),
                    ),
                  ),
                ),
              ),
            ),

            // Divider
            Container(
              width: 1,
              height: 24,
              color: colorScheme.outline.withOpacity(0.1),
            ),

            // Increment Button
            _StepperButton(
              icon: Icons.add,
              onPressed: _canIncrement ? _handleIncrement : null,
              enabled: _canIncrement,
              colorScheme: colorScheme,
              semanticLabel: 'Aumentar quantidade',
              isLeft: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal button widget for the stepper
class _StepperButton extends StatefulWidget {
  const _StepperButton({
    required this.icon,
    required this.onPressed,
    required this.enabled,
    required this.colorScheme,
    required this.semanticLabel,
    required this.isLeft,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final ColorScheme colorScheme;
  final String semanticLabel;
  final bool isLeft;

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isIncrement = !widget.isLeft;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: widget.enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          borderRadius: BorderRadius.horizontal(
            left: widget.isLeft ? const Radius.circular(12) : Radius.zero,
            right: !widget.isLeft ? const Radius.circular(12) : Radius.zero,
          ),
          splashColor: isIncrement
              ? widget.colorScheme.primary.withOpacity(0.2)
              : widget.colorScheme.surface.withOpacity(0.2),
          highlightColor: isIncrement
              ? widget.colorScheme.primary.withOpacity(0.1)
              : widget.colorScheme.surface.withOpacity(0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.horizontal(
                left: widget.isLeft ? const Radius.circular(12) : Radius.zero,
                right: !widget.isLeft ? const Radius.circular(12) : Radius.zero,
              ),
            ),
            child: Icon(widget.icon, size: 24, color: _getIconColor()),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    final isIncrement = !widget.isLeft;

    if (!widget.enabled) {
      return widget.colorScheme.surface.withOpacity(0.5);
    }

    if (isIncrement) {
      return _isPressed
          ? widget.colorScheme.primary.withOpacity(0.9)
          : widget.colorScheme.primary;
    }

    return _isPressed
        ? widget.colorScheme.surface.withOpacity(0.8)
        : widget.colorScheme.surface;
  }

  Color _getIconColor() {
    final isIncrement = !widget.isLeft;

    if (!widget.enabled) {
      return widget.colorScheme.onSurface.withOpacity(0.38);
    }

    if (isIncrement) {
      return widget.colorScheme.onPrimary;
    }

    return widget.colorScheme.onSurfaceVariant;
  }
}
