import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/tag.dart';

/// Thrown by [TagRepository.createTag] when the user already has a tag
/// with that name.
class TagAlreadyExistsException implements Exception {}

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

  Future<MimoTag> createTag(String name) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('createTag called with no signed-in user');
    }

    try {
      final inserted = await _client
          .from('tags')
          .insert({
            'owner_id': userId,
            'name': name.trim(),
            'color': '#7C5AE0',
            'is_system': false,
          })
          .select()
          .single();
      return MimoTag.fromJson(inserted);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw TagAlreadyExistsException(); // unique_violation
      rethrow;
    }
  }
}
