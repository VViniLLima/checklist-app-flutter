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
  final double price;
  final String quantity;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.categoryId,
    required this.createdAt,
    this.checkedAt,
    this.price = 0.0,
    this.quantity = '',
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    bool? isChecked,
    Object? categoryId = _sentinel,
    DateTime? createdAt,
    Object? checkedAt = _sentinel,
    double? price,
    String? quantity,
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
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
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
      'price': price,
      'quantity': quantity,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      isChecked: json['isChecked'] as bool? ?? false,
      categoryId: json['categoryId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      checkedAt: json['checkedAt'] != null
          ? DateTime.parse(json['checkedAt'] as String)
          : null,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as String? ?? '',
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
        other.price == price &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    isChecked,
    categoryId,
    createdAt,
    checkedAt,
    price,
    quantity,
  );

  @override
  String toString() =>
      'ShoppingItem(id: $id, name: $name, isChecked: $isChecked, categoryId: $categoryId, price: $price, quantity: $quantity)';
}
