/// Represents a single item within a meal option from the n8n webhook response.
///
/// Maps to JSON: `{ "item": "...", "category": "..." }`
/// Also supports legacy format: `{ "item": "...", "categoria": "..." }`
class N8nMealItem {
  final String item;
  final String category;

  N8nMealItem({required this.item, required this.category});

  factory N8nMealItem.fromJson(Map<String, dynamic> json) {
    return N8nMealItem(
      item: json['item'] as String? ?? 'Item desconhecido',
      category:
          json['category'] as String? ??
          json['categoria'] as String? ??
          'Sem categoria',
    );
  }

  /// Legacy accessor for backward compatibility
  String get categoria => category;
}

/// Represents a meal option from the n8n webhook response.
///
/// Maps to JSON: `{ "meal_name": "...", "items": [...] }`
/// Also supports legacy format: `{ "nome": "...", "itens": [...] }`
class N8nMeal {
  final String mealName;
  final List<N8nMealItem> items;

  N8nMeal({required this.mealName, required this.items});

  factory N8nMeal.fromJson(Map<String, dynamic> json) {
    // Support both new format (meal_name/items) and legacy format (nome/itens)
    final itemsJson =
        json['items'] as List<dynamic>? ??
        json['itens'] as List<dynamic>? ??
        [];
    return N8nMeal(
      mealName:
          json['meal_name'] as String? ??
          json['nome'] as String? ??
          'Refeição sem nome',
      items: itemsJson
          .map((i) => N8nMealItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Legacy accessor for backward compatibility
  String get nome => mealName;

  /// Legacy accessor for backward compatibility
  List<N8nMealItem> get itens => items;
}

/// Represents the full n8n webhook response containing meal options.
///
/// Maps to JSON: `{ "meal_options": [...] }`
/// Also supports legacy format: `{ "refeicoes": [...] }`
class N8nResponse {
  final List<N8nMeal> mealOptions;

  N8nResponse({required this.mealOptions});

  factory N8nResponse.fromJson(Map<String, dynamic> json) {
    final mealsJson =
        json['meal_options'] as List<dynamic>? ??
        json['refeicoes'] as List<dynamic>? ??
        json['normalized_name'] as List<dynamic>? ??
        [];
    return N8nResponse(
      mealOptions: mealsJson
          .map((r) => N8nMeal.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Legacy accessor for backward compatibility
  List<N8nMeal> get refeicoes => mealOptions;
}
