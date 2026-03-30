import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for persisting shopping lists in the Supabase database.
///
/// Handles the `public.listas_do_usuario` table for authenticated users.
/// Guest users are not supported — callers must check authentication first.
class SupabaseListService {
  final SupabaseClient _client;

  SupabaseListService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Inserts a manually created list into `public.listas_do_usuario`.
  ///
  /// Returns the full inserted row, including the DB-generated [id].
  /// Throws a [PostgrestException] or [Exception] on failure.
  Future<Map<String, dynamic>> insertManualList({
    required String userId,
    required String name,
    String? descricao,
    String moeda = 'BRL',
  }) async {
    final response = await _client
        .from('listas_do_usuario')
        .insert({
          'usuario_id': userId,
          'plano_alimentar_id': null,
          'llm_geracao_id': null,
          'nome': name,
          'descricao': descricao,
          'origem': 'manual',
          'status': 'ativa',
          'moeda': moeda,
          'finalizada_em': null,
        })
        .select()
        .single();

    return response;
  }

  /// Updates the name of an existing list in `public.listas_do_usuario`.
  ///
  /// Throws a [PostgrestException] or [Exception] on failure.
  Future<void> updateListName(String listId, String newName) async {
    await _client
        .from('listas_do_usuario')
        .update({'nome': newName})
        .eq('id', listId);
  }

  /// Deletes a list from `public.listas_do_usuario`.
  ///
  /// Throws a [PostgrestException] or [Exception] on failure.
  Future<void> deleteList(String listId) async {
    await _client.from('listas_do_usuario').delete().eq('id', listId);
  }

  /// Inserts a category into `public.categorias_da_lista`.
  ///
  /// Returns the full inserted row, including the DB-generated [id].
  /// Throws a [PostgrestException] or [Exception] on failure.
  Future<Map<String, dynamic>> insertCategory({
    required String listId,
    required String name,
    required String corHex,
    required int ordem,
    bool colapsada = false,
  }) async {
    final now = DateTime.now().toUtc();
    final response = await _client
        .from('categorias_da_lista')
        .insert({
          'lista_id': listId,
          'nome': name,
          'cor_hex': corHex,
          'ordem': ordem,
          'colapsada': colapsada,
          'criado_em': now.toIso8601String(),
          'atualizado_em': now.toIso8601String(),
        })
        .select()
        .single();

    return response;
  }

  /// Updates a category's name in `public.categorias_da_lista`.
  ///
  /// Throws a [PostgrestException] or [Exception] on failure.
  Future<void> updateCategoryName(String categoryId, String newName) async {
    final now = DateTime.now().toUtc();
    await _client
        .from('categorias_da_lista')
        .update({'nome': newName, 'atualizado_em': now.toIso8601String()})
        .eq('id', categoryId);
  }

  /// Updates a category's color in `public.categorias_da_lista`.
  ///
  /// Throws a [PostgrestException] or [Exception] on failure.
  Future<void> updateCategoryColor(String categoryId, String corHex) async {
    final now = DateTime.now().toUtc();
    await _client
        .from('categorias_da_lista')
        .update({'cor_hex': corHex, 'atualizado_em': now.toIso8601String()})
        .eq('id', categoryId);
  }

  /// Deletes a category from `public.categorias_da_lista`.
  ///
  /// Throws a [PostgrestException] or [Exception] on failure.
  Future<void> deleteCategory(String categoryId) async {
    await _client.from('categorias_da_lista').delete().eq('id', categoryId);
  }

  /// Updates a category's collapsed state in `public.categorias_da_lista`.
  ///
  /// Throws a [PostgrestException] or [Exception] on failure.
  Future<void> updateCategoryCollapsed(
    String categoryId,
    bool colapsada,
  ) async {
    final now = DateTime.now().toUtc();
    await _client
        .from('categorias_da_lista')
        .update({
          'colapsada': colapsada,
          'atualizado_em': now.toIso8601String(),
        })
        .eq('id', categoryId);
  }

  /// Updates a category's order in `public.categorias_da_lista`.
  ///
  /// Throws a [PostgrestException] or [Exception] on failure.
  Future<void> updateCategoryOrder(String categoryId, int ordem) async {
    final now = DateTime.now().toUtc();
    await _client
        .from('categorias_da_lista')
        .update({'ordem': ordem, 'atualizado_em': now.toIso8601String()})
        .eq('id', categoryId);
  }
  // ==================== Items ====================

  /// Inserts an item into `public.itens_da_lista`.
  ///
  /// [precoCentavos] is the unit price in cents (e.g. 250 = R$2.50).
  /// [totalCentavos] is the total value in cents.
  ///
  /// Returns the full inserted row, including the DB-generated [id].
  /// Throws a [PostgrestException] or [Exception] on failure.
  Future<Map<String, dynamic>> insertItem({
    required String listId,
    required String? categoryId,
    required String nome,
    required double quantidadeCompra,
    required String unidadeCompra,
    required int precoCentavos,
    required String unidadePreco,
    required int totalCentavos,
    required bool completo,
    required String origem,
    required int ordem,
    DateTime? completoEm,
    String? descricao,
    String? refeicaoOrigemResumo,
  }) async {
    final now = DateTime.now().toUtc();
    final response = await _client
        .from('itens_da_lista')
        .insert({
          'lista_id': listId,
          'categoria_id': categoryId,
          'nome': nome,
          'descricao': descricao,
          'quantidade_compra': quantidadeCompra,
          'unidade_compra': unidadeCompra,
          'preco_base_centavos': precoCentavos,
          'unidade_preco': unidadePreco,
          'valor_total_centavos': totalCentavos,
          'completo': completo,
          'completo_em': completoEm?.toUtc().toIso8601String(),
          'origem': origem,
          'refeicao_origem_resumo': refeicaoOrigemResumo,
          'ordem': ordem,
          'criado_em': now.toIso8601String(),
          'atualizado_em': now.toIso8601String(),
          'removido_em': null,
        })
        .select()
        .single();

    return response;
  }

  /// Updates mutable fields of an item in `public.itens_da_lista`.
  ///
  /// Only non-null parameters are included in the update payload.
  /// Throws a [PostgrestException] or [Exception] on failure.
  Future<void> updateItem({
    required String itemId,
    String? nome,
    String? categoryId,
    double? quantidadeCompra,
    String? unidadeCompra,
    int? precoCentavos,
    String? unidadePreco,
    int? totalCentavos,
    bool? completo,
    DateTime? completoEm,
    String? origem,
    int? ordem,
    String? descricao,
  }) async {
    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{'atualizado_em': now.toIso8601String()};

    if (nome != null) payload['nome'] = nome;
    if (categoryId != null) payload['categoria_id'] = categoryId;
    if (quantidadeCompra != null) {
      payload['quantidade_compra'] = quantidadeCompra;
    }
    if (unidadeCompra != null) payload['unidade_compra'] = unidadeCompra;
    if (precoCentavos != null) {
      payload['preco_base_centavos'] = precoCentavos;
    }
    if (unidadePreco != null) payload['unidade_preco'] = unidadePreco;
    if (totalCentavos != null) {
      payload['valor_total_centavos'] = totalCentavos;
    }
    if (completo != null) payload['completo'] = completo;
    if (completoEm != null) {
      payload['completo_em'] = completoEm.toUtc().toIso8601String();
    }
    if (origem != null) payload['origem'] = origem;
    if (ordem != null) payload['ordem'] = ordem;
    if (descricao != null) payload['descricao'] = descricao;

    await _client.from('itens_da_lista').update(payload).eq('id', itemId);
  }

  /// Soft-deletes an item by setting `removido_em` in `public.itens_da_lista`.
  ///
  /// The row is kept in the DB for audit/history purposes.
  /// Throws a [PostgrestException] or [Exception] on failure.
  Future<void> softDeleteItem(String itemId) async {
    final now = DateTime.now().toUtc();
    await _client
        .from('itens_da_lista')
        .update({
          'removido_em': now.toIso8601String(),
          'atualizado_em': now.toIso8601String(),
        })
        .eq('id', itemId);
  }
}
