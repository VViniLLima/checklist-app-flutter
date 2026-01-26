import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable number input widget with increment/decrement buttons
///
/// Features:
/// - Default value of 1 when empty
/// - Increment/decrement buttons on both sides
/// - Numeric-only input with decimal support
/// - Validation to prevent negative values or zero
/// - Styled to match the app's design system
/// - Accessibility labels for buttons
class NumberInputWidget extends StatelessWidget {
  const NumberInputWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    this.labelText = 'Quantidade',
    this.prefixIcon = Icons.scale_outlined,
    this.minValue = 0.01,
    this.step = 1.0,
    this.allowDecimals = true,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final String labelText;
  final IconData prefixIcon;
  final double minValue;
  final double step;
  final bool allowDecimals;

  void _increment() {
    final currentValue = _getCurrentValue();
    final newValue = currentValue + step;
    _setValue(newValue);
    onChanged();
  }

  void _decrement() {
    final currentValue = _getCurrentValue();
    final newValue = (currentValue - step).clamp(minValue, double.infinity);
    _setValue(newValue);
    onChanged();
  }

  double _getCurrentValue() {
    final text = controller.text.trim().replaceAll(',', '.');
    final value = double.tryParse(text) ?? 0.0;
    return value > 0 ? value : 1.0; // Default to 1 if empty or invalid
  }

  void _setValue(double value) {
    // Format the value based on whether it's a whole number or decimal
    String formattedValue;
    if (value % 1 == 0) {
      formattedValue = value.toInt().toString();
    } else {
      formattedValue = value.toString().replaceAll('.', ',');
    }
    controller.text = formattedValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Decrement button
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.remove, size: 20, color: colorScheme.primary),
            onPressed: _decrement,
            tooltip: 'Diminuir quantidade',
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 8),

        // Text field
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(
              decimal: allowDecimals,
            ),
            inputFormatters: [
              if (allowDecimals)
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*'))
              else
                FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (_) {
              // Validate and ensure minimum value
              final text = controller.text.trim().replaceAll(',', '.');
              final value = double.tryParse(text);

              // If empty or invalid, don't trigger onChanged yet
              if (text.isEmpty || value == null) {
                return;
              }

              // If value is less than minimum, set to minimum
              if (value < minValue) {
                _setValue(minValue);
              }

              onChanged();
            },
            onTap: () {
              // If field is empty, set default value of 1
              if (controller.text.trim().isEmpty) {
                controller.text = '1';
                controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: controller.text.length,
                );
              }
            },
            decoration: InputDecoration(
              labelText: labelText,
              prefixIcon: Icon(prefixIcon),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),

        // Increment button
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.add, size: 20, color: colorScheme.primary),
            onPressed: _increment,
            tooltip: 'Aumentar quantidade',
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
