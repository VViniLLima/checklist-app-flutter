import 'package:flutter/foundation.dart';

/// Representa um item individual na lista de compras
/// 
/// Cada item pertence a uma categoria (ou nenhuma se categoryId for null)
/// e possui estado de marcação (checked/unchecked) com timestamps para ordenação
@immutable
class ShoppingItem {
  final String id;
  final String name;
  final bool isChecked;
  final String? categoryId; // null = "Sem categoria"
  final DateTime createdAt;
  final DateTime? checkedAt;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.categoryId,
    required this.createdAt,
    this.checkedAt,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    bool? isChecked,
    String? categoryId,
    DateTime? createdAt,
    DateTime? checkedAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      checkedAt: checkedAt ?? this.checkedAt,
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
        other.checkedAt == checkedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        isChecked,
        categoryId,
        createdAt,
        checkedAt,
      );

  @override
  String toString() =>
      'ShoppingItem(id: $id, name: $name, isChecked: $isChecked, categoryId: $categoryId)';
}
