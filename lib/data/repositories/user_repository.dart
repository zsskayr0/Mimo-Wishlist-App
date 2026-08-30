import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

/// Thrown by [UserRepository.updateProfile] when the chosen @username is
/// already someone else's.
class UsernameAlreadyTakenException implements Exception {}

/// The current user's own `public.users` row — separate from
/// [FriendshipRepository], which only ever looks at *other* users.
class UserRepository {
  UserRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<UserProfile> fetchMe() async {
    final id = _client.auth.currentUser!.id;
    final row = await _client.from('users').select().eq('id', id).single();
    return UserProfile.fromJson(row);
  }

  Future<void> updateProfile({
    required String userId,
    required String username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      await _client.from('users').update({
        'username': username.trim().toLowerCase(),
        'display_name': (displayName == null || displayName.trim().isEmpty) ? null : displayName.trim(),
        'avatar_url': avatarUrl,
        'bio': (bio == null || bio.trim().isEmpty) ? null : bio.trim(),
      }).eq('id', userId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw UsernameAlreadyTakenException(); // unique_violation
      rethrow;
    }
  }
}
