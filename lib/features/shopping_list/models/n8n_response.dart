class N8nMealItem {
  final String item;
  final String categoria;

  N8nMealItem({required this.item, required this.categoria});

  factory N8nMealItem.fromJson(Map<String, dynamic> json) {
    return N8nMealItem(
      item: json['item'] as String? ?? 'Item desconhecido',
      categoria: json['categoria'] as String? ?? 'Sem categoria',
    );
  }
}

class N8nMeal {
  final String nome;
  final List<N8nMealItem> itens;

  N8nMeal({required this.nome, required this.itens});

  factory N8nMeal.fromJson(Map<String, dynamic> json) {
    final itensJson = json['itens'] as List<dynamic>? ?? [];
    return N8nMeal(
      nome: json['nome'] as String? ?? 'Refeição sem nome',
      itens: itensJson
          .map((i) => N8nMealItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class N8nResponse {
  final List<N8nMeal> refeicoes;

  N8nResponse({required this.refeicoes});

  factory N8nResponse.fromJson(Map<String, dynamic> json) {
    final refeicoesJson = json['refeicoes'] as List<dynamic>? ?? [];
    return N8nResponse(
      refeicoes: refeicoesJson
          .map((r) => N8nMeal.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
