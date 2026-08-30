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
///
/// `users!folders_owner_id_fkey` — folders has *two* paths to users (the
/// owner_id FK directly, and the folder_members many-to-many), so a plain
/// `users(...)` embed is ambiguous to Postgrest (PGRST201); this names the
/// specific relationship. Always embedded now (not just in
/// fetchSharedWithMe) — FolderOptionsSheet's member list needs the
/// owner's profile regardless of which list the Folder came from.
class FolderRepository {
  FolderRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const _folderSelect =
      '*, mimos(count), folder_members(users(avatar_url)), users!folders_owner_id_fkey(username, display_name, avatar_url)';

  final SupabaseClient _client;

  /// Refetches one folder with fresh data — used after FolderOptionsSheet
  /// closes, in case name/color/cover changed there.
  Future<Folder> fetchFolder(String folderId) async {
    final row = await _client
        .from('folders')
        .select(_folderSelect)
        .eq('id', folderId)
        .single();
    return Folder.fromJson(row);
  }

  Future<List<Folder>> fetchFolders() async {
    final rows = await _client
        .from('folders')
        .select(_folderSelect)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Folder.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Folders someone else shared with the current user — for the Amigos
  /// screen's "Pastas compartilhadas com você" section.
  Future<List<Folder>> fetchSharedWithMe() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final rows = await _client
        .from('folders')
        .select(_folderSelect)
        .neq('owner_id', userId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Folder.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Returns the created row (rather than void) so the caller can show it
  /// immediately instead of waiting on a full list refetch.
  Future<Folder> createFolder({
    required String name,
    required String color,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('createFolder called with no signed-in user');
    }

    final inserted = await _client
        .from('folders')
        .insert({'owner_id': userId, 'name': name, 'color': color})
        .select(_folderSelect)
        .single();
    return Folder.fromJson(inserted);
  }

  /// Rename/recolor/re-cover an existing folder ("customizar a pasta").
  /// `coverImageUrl` uses the nullable-clearing-function pattern (see
  /// Mimo.copyWith) so callers can distinguish "leave it" from "clear it".
  Future<void> updateFolder({
    required String folderId,
    String? name,
    String? color,
    String? Function()? coverImageUrl,
  }) async {
    final patch = <String, dynamic>{
      'name': ?name,
      'color': ?color,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl(),
    };
    if (patch.isEmpty) return;
    await _client.from('folders').update(patch).eq('id', folderId);
  }

  Future<void> deleteFolder(String folderId) async {
    await _client.from('folders').delete().eq('id', folderId);
  }

  /// See migration 008 for why this is an RPC rather than a plain update
  /// — RLS's implicit WITH CHECK on folders_update_owner_or_editor
  /// rejects a direct owner_id change.
  Future<void> transferOwnership({
    required String folderId,
    required String newOwnerId,
  }) async {
    await _client.rpc(
      'transfer_folder_ownership',
      params: {'p_folder_id': folderId, 'p_new_owner_id': newOwnerId},
    );
  }

  Future<List<FolderMember>> fetchMembers(String folderId) async {
    final rows = await _client
        .from('folder_members')
        .select('role, users(id, username, display_name, avatar_url)')
        .eq('folder_id', folderId);

    return (rows as List)
        .map((row) => FolderMember.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Looks a user up by @username and adds them to the folder. Kept for
  /// an exact-match fallback; `InviteMemberSheet` normally already has
  /// the userId from its live search and calls [addMember] directly.
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
    await addMember(
      folderId: folderId,
      userId: userRows.first['id'] as String,
      role: role,
    );
  }

  /// Adds a known user (already resolved — e.g. picked from a search
  /// result) to the folder. Only the folder's owner can actually do
  /// this — `folder_members_manage_owner` enforces that server-side
  /// regardless of what the UI shows.
  Future<void> addMember({
    required String folderId,
    required String userId,
    required String role,
  }) async {
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

    await _client
        .from('folders')
        .update({'is_shared': true})
        .eq('id', folderId);
  }

  Future<void> removeMember(String folderId, String userId) async {
    await _client
        .from('folder_members')
        .delete()
        .eq('folder_id', folderId)
        .eq('user_id', userId);
  }
}
