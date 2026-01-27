import 'package:flutter/foundation.dart';

/// Representa uma lista de compras completa
///
/// Cada lista contém um nome e um ID único
@immutable
class ShoppingList {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  final bool isCompleted;
  final bool isFavorite;
  final String? purchaseLocation;
  final DateTime? purchaseDate;
  final double? totalSpent;

  const ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastModifiedAt,
    this.isCompleted = false,
    this.isFavorite = false,
    this.purchaseLocation,
    this.purchaseDate,
    this.totalSpent,
  });

  ShoppingList copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
    bool? isCompleted,
    bool? isFavorite,
    String? purchaseLocation,
    DateTime? purchaseDate,
    double? totalSpent,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      isFavorite: isFavorite ?? this.isFavorite,
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
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      'isCompleted': isCompleted,
      'isFavorite': isFavorite,
      'purchaseLocation': purchaseLocation,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'totalSpent': totalSpent,
    };
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'] as String);
    return ShoppingList(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: createdAt,
      lastModifiedAt: json['lastModifiedAt'] != null
          ? DateTime.parse(json['lastModifiedAt'] as String)
          : (json['updatedAt'] != null
                ? DateTime.parse(json['updatedAt'] as String)
                : createdAt),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
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
        other.lastModifiedAt == lastModifiedAt &&
        other.isCompleted == isCompleted &&
        other.isFavorite == isFavorite &&
        other.purchaseLocation == purchaseLocation &&
        other.purchaseDate == purchaseDate &&
        other.totalSpent == totalSpent;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    createdAt,
    lastModifiedAt,
    isCompleted,
    isFavorite,
    purchaseLocation,
    purchaseDate,
    totalSpent,
  );

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, isCompleted: $isCompleted, totalSpent: $totalSpent, lastModifiedAt: $lastModifiedAt)';
  }
}
