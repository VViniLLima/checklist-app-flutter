import 'package:flutter/foundation.dart';

/// Representa um item individual na lista de compras
///
/// Cada item pertence a uma categoria (ou nenhuma se categoryId for null)
/// e possui estado de marcação (checked/unchecked) com timestamps para ordenação
const Object _sentinel = Object();

@immutable
class ShoppingItem {
  final String id;
  final String name;
  final bool isChecked;
  final String? categoryId; // null = "Sem categoria"
  final DateTime createdAt;
  final DateTime? checkedAt;
  final double quantityValue;
  final String quantityUnit;
  final double priceValue;
  final String priceUnit;
  final double totalValue;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.categoryId,
    required this.createdAt,
    this.checkedAt,
    this.quantityValue = 0.0,
    this.quantityUnit = 'und',
    this.priceValue = 0.0,
    this.priceUnit = 'und',
    this.totalValue = 0.0,
  });

  static const List<String> units = [
    'ml',
    'g',
    'mg',
    'kg',
    'L',
    'und',
    'caixa',
    'garrafa',
    'lata',
    'pacote',
  ];

  ShoppingItem copyWith({
    String? id,
    String? name,
    bool? isChecked,
    Object? categoryId = _sentinel,
    DateTime? createdAt,
    Object? checkedAt = _sentinel,
    double? quantityValue,
    String? quantityUnit,
    double? priceValue,
    String? priceUnit,
    double? totalValue,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
      categoryId: categoryId == _sentinel
          ? this.categoryId
          : categoryId as String?,
      createdAt: createdAt ?? this.createdAt,
      checkedAt: checkedAt == _sentinel
          ? this.checkedAt
          : checkedAt as DateTime?,
      quantityValue: quantityValue ?? this.quantityValue,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      priceValue: priceValue ?? this.priceValue,
      priceUnit: priceUnit ?? this.priceUnit,
      totalValue: totalValue ?? this.totalValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isChecked': isChecked,
      'categoryId': categoryId,
      'createdAt': createdAt.toIso8601String(),
      'checkedAt': checkedAt?.toIso8601String(),
      'quantityValue': quantityValue,
      'quantityUnit': quantityUnit,
      'priceValue': priceValue,
      'priceUnit': priceUnit,
      'totalValue': totalValue,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    // Migration logic for old fields
    final double qValue = (json['quantityValue'] as num?)?.toDouble() ?? 0.0;
    String qUnit = json['quantityUnit'] as String? ?? 'und';
    if (qUnit == 'un') qUnit = 'und';

    final double pValue = (json['priceValue'] as num?)?.toDouble() ?? 0.0;
    String pUnit = json['priceUnit'] as String? ?? 'und';
    if (pUnit == 'un') pUnit = 'und';

    double tValue = (json['totalValue'] as num?)?.toDouble() ?? 0.0;

    // If totalValue is missing but old price exists, use it as a fallback for simple items
    if (!json.containsKey('totalValue') && json.containsKey('price')) {
      tValue = (json['price'] as num?)?.toDouble() ?? 0.0;
    }

    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      isChecked: json['isChecked'] as bool? ?? false,
      categoryId: json['categoryId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      checkedAt: json['checkedAt'] != null
          ? DateTime.parse(json['checkedAt'] as String)
          : null,
      quantityValue: qValue,
      quantityUnit: qUnit,
      priceValue: pValue,
      priceUnit: pUnit,
      totalValue: tValue,
    );
  }

  static double calculateTotal(
    double qVal,
    String qUnit,
    double pVal,
    String pUnit,
  ) {
    if (qUnit == pUnit) {
      return qVal * pVal;
    }

    // Mass Family: mg, g, kg
    const massFactors = {'mg': 1.0, 'g': 1000.0, 'kg': 1000000.0};
    if (massFactors.containsKey(qUnit) && massFactors.containsKey(pUnit)) {
      final qInMg = qVal * massFactors[qUnit]!;
      final pPerMg = pVal / massFactors[pUnit]!;
      return qInMg * pPerMg;
    }

    // Volume Family: ml, L
    const volumeFactors = {'ml': 1.0, 'L': 1000.0};
    if (volumeFactors.containsKey(qUnit) && volumeFactors.containsKey(pUnit)) {
      final qInMl = qVal * volumeFactors[qUnit]!;
      final pPerMl = pVal / volumeFactors[pUnit]!;
      return qInMl * pPerMl;
    }

    // Incompatible
    return 0.0;
  }

  /// Returns 0 for unchecked, and the quantity count for checked items with countable units.
  static int getCompletedCountContribution(ShoppingItem item) {
    if (!item.isChecked) return 0;
    return getCountContribution(item);
  }

  /// Returns the count contribution for an item based on its unit and quantity.
  ///
  /// Countable units (un, und, caixa, garrafa, lata, pacote) contribute their quantity.
  /// Measurement units (ml, g, mg, kg, L) always contribute 1.
  /// Fallback is always 1.
  static int getCountContribution(ShoppingItem item) {
    // Countable units: quantity affects count
    const countableUnits = {'und', 'caixa', 'garrafa', 'lata', 'pacote'};

    if (countableUnits.contains(item.quantityUnit)) {
      return item.quantityValue > 0
          ? item.quantityValue.toInt().clamp(1, 999999)
          : 1;
    }

    // Measurement units or unknown units always count as 1 entry
    return 1;
  }

  /// Sums the count contribution of all items in the list.
  static int getTotalCount(List<ShoppingItem> items) {
    return items.fold(0, (sum, item) => sum + getCountContribution(item));
  }

  /// Sums the count contribution of all checked items in the list.
  static int getCompletedCount(List<ShoppingItem> items) {
    return items.fold(
      0,
      (sum, item) => sum + getCompletedCountContribution(item),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingItem &&
        other.id == id &&
        other.name == name &&
        other.isChecked == isChecked &&
        other.categoryId == categoryId &&
        other.createdAt == createdAt &&
        other.checkedAt == checkedAt &&
        other.quantityValue == quantityValue &&
        other.quantityUnit == quantityUnit &&
        other.priceValue == priceValue &&
        other.priceUnit == priceUnit &&
        other.totalValue == totalValue;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    isChecked,
    categoryId,
    createdAt,
    checkedAt,
    quantityValue,
    quantityUnit,
    priceValue,
    priceUnit,
    totalValue,
  );

  @override
  String toString() =>
      'ShoppingItem(id: $id, name: $name, totalValue: $totalValue)';
}
