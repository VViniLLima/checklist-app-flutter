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
  final int
  sortOrder; // Ordem persistida da categoria (0 = primeiro após sem-categoria)
  final String corHex; // Hex color string for Supabase (e.g., "#E3F2FD")
  final DateTime criadoEm; // Timestamp when category was created
  final DateTime atualizadoEm; // Timestamp when category was last updated

  Category({
    required this.id,
    required this.name,
    this.isCollapsed = false,
    this.colorValue = 0xFFE3F2FD, // Colors.blue.shade50 default
    this.sortOrder = 0,
    this.corHex = '#E3F2FD',
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) : criadoEm = criadoEm ?? DateTime(1970),
       atualizadoEm = atualizadoEm ?? DateTime(1970);

  /// Retorna a cor como objeto Color
  Color get color => Color(colorValue);

  /// Factory constructor for creating a new category with current timestamp
  factory Category.create({
    required String id,
    required String name,
    bool isCollapsed = false,
    int colorValue = 0xFFE3F2FD,
    int sortOrder = 0,
    String corHex = '#E3F2FD',
  }) {
    final now = DateTime.now();
    return Category(
      id: id,
      name: name,
      isCollapsed: isCollapsed,
      colorValue: colorValue,
      sortOrder: sortOrder,
      corHex: corHex,
      criadoEm: now,
      atualizadoEm: now,
    );
  }

  Category copyWith({
    String? id,
    String? name,
    bool? isCollapsed,
    int? colorValue,
    int? sortOrder,
    String? corHex,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      corHex: corHex ?? this.corHex,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCollapsed': isCollapsed,
      'colorValue': colorValue,
      'sortOrder': sortOrder,
      'corHex': corHex,
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm.toIso8601String(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      isCollapsed: json['isCollapsed'] as bool? ?? false,
      colorValue: json['colorValue'] as int? ?? 0xFFE3F2FD,
      sortOrder: json['sortOrder'] as int? ?? 0,
      corHex: json['corHex'] as String? ?? '#E3F2FD',
      criadoEm: json['criadoEm'] != null
          ? DateTime.parse(json['criadoEm'] as String)
          : DateTime.now(),
      atualizadoEm: json['atualizadoEm'] != null
          ? DateTime.parse(json['atualizadoEm'] as String)
          : DateTime.now(),
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
        other.sortOrder == sortOrder &&
        other.corHex == corHex &&
        other.criadoEm == criadoEm &&
        other.atualizadoEm == atualizadoEm;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    isCollapsed,
    colorValue,
    sortOrder,
    corHex,
    criadoEm,
    atualizadoEm,
  );

  @override
  String toString() =>
      'Category(id: $id, name: $name, isCollapsed: $isCollapsed, colorValue: $colorValue)';
}
