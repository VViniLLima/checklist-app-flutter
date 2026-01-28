import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/features/shopping_list/models/shopping_item.dart';

void main() {
  group('ShoppingItem Counting Logic', () {
    test('Countable unit (lata) with quantity 3 contributes 3', () {
      final item = ShoppingItem(
        id: '1',
        name: 'Soda',
        createdAt: DateTime.now(),
        quantityValue: 3,
        quantityUnit: 'lata',
      );
      expect(ShoppingItem.getCountContribution(item), 3);
    });

    test('Measurement unit (g) with quantity 200 contributes 1', () {
      final item = ShoppingItem(
        id: '2',
        name: 'Ham',
        createdAt: DateTime.now(),
        quantityValue: 200,
        quantityUnit: 'g',
      );
      expect(ShoppingItem.getCountContribution(item), 1);
    });

    test('Countable unit (und) with quantity 5 contributes 5', () {
      final item = ShoppingItem(
        id: '3',
        name: 'Eggs',
        createdAt: DateTime.now(),
        quantityValue: 5,
        quantityUnit: 'und',
      );
      expect(ShoppingItem.getCountContribution(item), 5);
    });

    test('Fallback to 1 for unknown unit', () {
      final item = ShoppingItem(
        id: '4',
        name: 'Custom',
        createdAt: DateTime.now(),
        quantityValue: 10,
        quantityUnit: 'box', // not in countable list
      );
      expect(ShoppingItem.getCountContribution(item), 1);
    });

    test('Handle quantity 0/negative by returning 1', () {
      final item0 = ShoppingItem(
        id: '5',
        name: 'Zero',
        createdAt: DateTime.now(),
        quantityValue: 0,
        quantityUnit: 'un',
      );
      final itemNeg = ShoppingItem(
        id: '6',
        name: 'Neg',
        createdAt: DateTime.now(),
        quantityValue: -5,
        quantityUnit: 'un',
      );
      expect(ShoppingItem.getCountContribution(item0), 1);
      expect(ShoppingItem.getCountContribution(itemNeg), 1);
    });

    test('getTotalCount sums correctly', () {
      final items = [
        ShoppingItem(
          id: '1',
          name: 'A',
          createdAt: DateTime.now(),
          quantityValue: 3,
          quantityUnit: 'und',
        ), // 3
        ShoppingItem(
          id: '2',
          name: 'B',
          createdAt: DateTime.now(),
          quantityValue: 500,
          quantityUnit: 'g',
        ), // 1
        ShoppingItem(
          id: '3',
          name: 'C',
          createdAt: DateTime.now(),
          quantityValue: 1,
          quantityUnit: 'un',
        ), // 1
      ];
      expect(ShoppingItem.getTotalCount(items), 5);
    });

    test('getCompletedCount only sums checked items', () {
      final items = [
        ShoppingItem(
          id: '1',
          name: 'A',
          createdAt: DateTime.now(),
          quantityValue: 3,
          quantityUnit: 'und',
          isChecked: true,
        ), // 3
        ShoppingItem(
          id: '2',
          name: 'B',
          createdAt: DateTime.now(),
          quantityValue: 500,
          quantityUnit: 'g',
          isChecked: false,
        ), // 0
        ShoppingItem(
          id: '3',
          name: 'C',
          createdAt: DateTime.now(),
          quantityValue: 2,
          quantityUnit: 'un',
          isChecked: true,
        ), // 2
      ];
      expect(ShoppingItem.getCompletedCount(items), 5);
    });
  });
}
