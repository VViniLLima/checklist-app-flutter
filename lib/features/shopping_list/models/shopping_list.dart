import 'package:flutter/foundation.dart';

/// Representa uma lista de compras completa
///
/// Cada lista contém um nome e um ID único
@immutable
class ShoppingList {
  final String id;
  final String name;
  final DateTime createdAt;
  final bool isCompleted;
  final String? purchaseLocation;
  final DateTime? purchaseDate;
  final double? totalSpent;

  const ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isCompleted = false,
    this.purchaseLocation,
    this.purchaseDate,
    this.totalSpent,
  });

  ShoppingList copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    bool? isCompleted,
    String? purchaseLocation,
    DateTime? purchaseDate,
    double? totalSpent,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      purchaseLocation: purchaseLocation ?? this.purchaseLocation,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
      'purchaseLocation': purchaseLocation,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'totalSpent': totalSpent,
    };
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      purchaseLocation: json['purchaseLocation'] as String?,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
      totalSpent: (json['totalSpent'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingList &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.isCompleted == isCompleted &&
        other.purchaseLocation == purchaseLocation &&
        other.purchaseDate == purchaseDate &&
        other.totalSpent == totalSpent;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    createdAt,
    isCompleted,
    purchaseLocation,
    purchaseDate,
    totalSpent,
  );

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, isCompleted: $isCompleted, totalSpent: $totalSpent)';
  }
}
