import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/folder.dart';

/// Talks to `public.folders`. No manual owner-or-member filtering here —
/// the `folders_select_owner_or_member` RLS policy already returns exactly
/// the folders this user owns or belongs to, so a plain select is correct.
class FolderRepository {
  FolderRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Folder>> fetchFolders() async {
    final rows = await _client
        .from('folders')
        .select('*, mimos(count)')
        .order('created_at', ascending: false);

    return (rows as List).map((row) => Folder.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<void> createFolder({required String name, required String color}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('createFolder called with no signed-in user');
    }

    await _client.from('folders').insert({
      'owner_id': userId,
      'name': name,
      'color': color,
    });
  }
}
