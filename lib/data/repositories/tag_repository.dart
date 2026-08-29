import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/tag.dart';

class TagRepository {
  TagRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// System tags (Casa, Tech...) plus whatever the current user created —
  /// exactly what `tags_select`'s RLS already limits this query to.
  Future<List<MimoTag>> fetchAvailableTags() async {
    final rows = await _client
        .from('tags')
        .select()
        .order('is_system', ascending: false)
        .order('name');

    return (rows as List).map((row) => MimoTag.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<List<MimoTag>> fetchTagsForMimo(String mimoId) async {
    final rows = await _client
        .from('mimo_tags')
        .select('tags(id, name, color, is_system)')
        .eq('mimo_id', mimoId);

    return (rows as List)
        .map((row) => MimoTag.fromJson((row as Map<String, dynamic>)['tags'] as Map<String, dynamic>))
        .toList();
  }
}
