import 'dart:convert';

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
    final rawItems = json['items'] ?? json['itens'];
    final List<dynamic> itemsJson = _coerceToList(rawItems);

    return N8nMeal(
      mealName:
          json['meal_name'] as String? ??
          json['nome'] as String? ??
          'Refeição sem nome',
      items: itemsJson
          .map((i) {
            if (i is Map<String, dynamic>) {
              return N8nMealItem.fromJson(i);
            } else if (i is String) {
              // If an item is a plain string, treat it as item name with no category
              return N8nMealItem(item: i, category: 'Sem categoria');
            }
            return null;
          })
          .whereType<N8nMealItem>()
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
    final rawMeals = json['meal_options'] ?? json['refeicoes'];
    final List<dynamic> mealsJson = _coerceToList(rawMeals);

    return N8nResponse(
      mealOptions: mealsJson
          .map((r) {
            if (r is Map<String, dynamic>) {
              return N8nMeal.fromJson(r);
            }
            return null;
          })
          .whereType<N8nMeal>()
          .toList(),
    );
  }

  /// Parses a webhook response body string into an [N8nResponse].
  ///
  /// Handles cases where the response is:
  /// - A JSON object with `meal_options` or `refeicoes` key
  /// - A JSON array wrapping such an object (e.g., `[{...}]`)
  /// - A stringified JSON that needs double-decoding
  factory N8nResponse.fromResponseBody(String body) {
    dynamic decoded = jsonDecode(body);

    // If the response is a list, unwrap the first element
    if (decoded is List && decoded.isNotEmpty) {
      decoded = decoded.first;
    }

    if (decoded is Map<String, dynamic>) {
      return N8nResponse.fromJson(decoded);
    }

    // If we still can't parse it, return empty
    return N8nResponse(mealOptions: []);
  }

  /// Legacy accessor for backward compatibility
  List<N8nMeal> get refeicoes => mealOptions;
}

/// Coerces a dynamic value into a List<dynamic>.
///
/// Handles cases where the value is:
/// - Already a List
/// - A JSON string that decodes to a List
/// - null (returns empty list)
List<dynamic> _coerceToList(dynamic value) {
  if (value == null) return [];
  if (value is List<dynamic>) return value;
  if (value is String) {
    // Try to parse as JSON array
    try {
      final parsed = jsonDecode(value);
      if (parsed is List<dynamic>) return parsed;
    } catch (_) {
      // Not valid JSON, ignore
    }
  }
  return [];
}
