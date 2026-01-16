import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Representa uma categoria de itens na lista de compras
///
/// Cada categoria pode ser colapsada/expandida e agrupa itens relacionados
@immutable
class Category {
  final String id;
  final String name;
  final bool isCollapsed;
  final int colorValue; // Armazena o valor da cor como int
  final int sortOrder; // Ordem persistida da categoria (0 = primeiro após sem-categoria)

  const Category({
    required this.id,
    required this.name,
    this.isCollapsed = false,
    this.colorValue = 0xFFE3F2FD, // Colors.blue.shade50 default
    this.sortOrder = 0,
  });

  /// Retorna a cor como objeto Color
  Color get color => Color(colorValue);

  Category copyWith({
    String? id,
    String? name,
    bool? isCollapsed,
    int? colorValue,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCollapsed': isCollapsed,
      'colorValue': colorValue,
      'sortOrder': sortOrder,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      isCollapsed: json['isCollapsed'] as bool? ?? false,
      colorValue: json['colorValue'] as int? ?? 0xFFE3F2FD,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.isCollapsed == isCollapsed &&
        other.colorValue == colorValue &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(id, name, isCollapsed, colorValue, sortOrder);

  @override
  String toString() => 'Category(id: $id, name: $name, isCollapsed: $isCollapsed, colorValue: $colorValue)';
}
