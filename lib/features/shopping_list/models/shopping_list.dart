import 'package:flutter/foundation.dart';

/// Representa uma lista de compras completa
/// 
/// Cada lista contém um nome e um ID único
@immutable
class ShoppingList {
  final String id;
  final String name;
  final DateTime createdAt;

  const ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  ShoppingList copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingList &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);

  @override
  String toString() => 'ShoppingList(id: $id, name: $name, createdAt: $createdAt)';
}
