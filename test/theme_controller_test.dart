import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/core/theme/theme_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeController', () {
    test('Initial theme should be system', () {
      final controller = ThemeController();
      expect(controller.themeMode, ThemeMode.system);
    });

    test('Tapping toggle should switch between light and dark', () async {
      final controller = ThemeController();

      // Default is system, first toggle will go to Dark (if we follow our logic in toggleTheme)
      // Actually, my implementation was:
      // if (_themeMode == ThemeMode.light) { _themeMode = ThemeMode.dark; } else { _themeMode = ThemeMode.light; }
      // So if it's system, it goes to light.

      await controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.light);

      await controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.dark);

      await controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.light);
    });

    test('Persistence should work', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'ThemeMode.dark'});

      final controller = ThemeController();

      // Need to wait for the async load in constructor
      // Since it's called in constructor, we might need a way to await it or just wait a bit
      await Future.delayed(Duration.zero);

      expect(controller.themeMode, ThemeMode.dark);
    });
  });
}
