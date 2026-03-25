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
}
