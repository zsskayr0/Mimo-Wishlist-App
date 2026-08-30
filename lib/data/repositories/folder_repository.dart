import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/folder.dart';
import '../models/folder_member.dart';

/// Thrown by [FolderRepository.inviteMember] when the @username doesn't
/// match anyone.
class UserNotFoundException implements Exception {}

/// Thrown by [FolderRepository.inviteMember] when that user is already a
/// member of the folder.
class AlreadyMemberException implements Exception {}

/// Talks to `public.folders` and `public.folder_members`. No manual
/// owner-or-member filtering on folders — the
/// `folders_select_owner_or_member` RLS policy already returns exactly the
/// folders this user owns or belongs to, so a plain select is correct.
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

  /// Folders someone else shared with the current user — for the Amigos
  /// screen's "Pastas compartilhadas com você" section. RLS already limits
  /// `folders` to owner-or-member; `neq('owner_id', ...)` narrows that down
  /// to just the "member, not owner" half, and the `users(username)` embed
  /// is what lets that section say who shared it.
  ///
  /// `users!folders_owner_id_fkey` — folders actually has *two* paths to
  /// users (the owner_id FK directly, and the folder_members many-to-many),
  /// so a plain `users(username)` is ambiguous to Postgrest (PGRST201);
  /// this names the specific relationship to embed.
  Future<List<Folder>> fetchSharedWithMe() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final rows = await _client
        .from('folders')
        .select('*, mimos(count), users!folders_owner_id_fkey(username)')
        .neq('owner_id', userId)
        .order('created_at', ascending: false);

    return (rows as List).map((row) => Folder.fromJson(row as Map<String, dynamic>)).toList();
  }

  /// Returns the created row (rather than void) so the caller can show it
  /// immediately instead of waiting on a full list refetch.
  Future<Folder> createFolder({required String name, required String color}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('createFolder called with no signed-in user');
    }

    final inserted = await _client
        .from('folders')
        .insert({'owner_id': userId, 'name': name, 'color': color})
        .select()
        .single();
    return Folder.fromJson(inserted);
  }

  Future<List<FolderMember>> fetchMembers(String folderId) async {
    final rows = await _client
        .from('folder_members')
        .select('role, users(id, username, display_name)')
        .eq('folder_id', folderId);

    return (rows as List).map((row) => FolderMember.fromJson(row as Map<String, dynamic>)).toList();
  }

  /// Looks a user up by @username and adds them to the folder. Only the
  /// folder's owner can actually do this — `folder_members_manage_owner`
  /// enforces that server-side regardless of what the UI shows.
  Future<void> inviteMember({
    required String folderId,
    required String username,
    required String role,
  }) async {
    final userRows = await _client
        .from('users')
        .select('id')
        .eq('username', username.trim().toLowerCase())
        .limit(1);

    if ((userRows as List).isEmpty) {
      throw UserNotFoundException();
    }
    final userId = userRows.first['id'] as String;

    try {
      await _client.from('folder_members').insert({
        'folder_id': folderId,
        'user_id': userId,
        'role': role,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw AlreadyMemberException(); // unique_violation
      rethrow;
    }

    await _client.from('folders').update({'is_shared': true}).eq('id', folderId);
  }

  Future<void> removeMember(String folderId, String userId) async {
    await _client.from('folder_members').delete().eq('folder_id', folderId).eq('user_id', userId);
  }
}
