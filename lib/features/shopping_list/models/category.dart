import 'package:flutter/foundation.dart';

/// Representa uma categoria de itens na lista de compras
/// 
/// Cada categoria pode ser colapsada/expandida e agrupa itens relacionados
@immutable
class Category {
  final String id;
  final String name;
  final bool isCollapsed;

  const Category({
    required this.id,
    required this.name,
    this.isCollapsed = false,
  });

  Category copyWith({
    String? id,
    String? name,
    bool? isCollapsed,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCollapsed': isCollapsed,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      isCollapsed: json['isCollapsed'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.isCollapsed == isCollapsed;
  }

  @override
  int get hashCode => Object.hash(id, name, isCollapsed);

  @override
  String toString() => 'Category(id: $id, name: $name, isCollapsed: $isCollapsed)';
}
