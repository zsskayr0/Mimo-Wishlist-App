import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

/// Thrown by [FriendshipRepository.sendRequest] when a friendship (either
/// direction, any status) already exists between the two users — the
/// "check both directions before creating a new request" responsibility
/// the schema comment leaves to the app layer.
class FriendshipAlreadyExistsException implements Exception {}

/// Talks to `public.friendships` and `public.users`. Postgres has two FKs
/// from friendships to users (requester_id, addressee_id), so rather than
/// lean on a disambiguated embed, this fetches friendship rows and profiles
/// in two simple, separately-readable steps.
class FriendshipRepository {
  FriendshipRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _myId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('FriendshipRepository used with no signed-in user');
    return id;
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final rows = await _client
        .from('users')
        .select()
        .ilike('username', '%$trimmed%')
        .neq('id', _myId)
        .limit(15);

    return (rows as List).map((row) => UserProfile.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<List<UserProfile>> fetchFriends() async {
    final myId = _myId;
    final rows = await _client
        .from('friendships')
        .select('requester_id, addressee_id')
        .eq('status', 'aceita')
        .or('requester_id.eq.$myId,addressee_id.eq.$myId');

    final otherIds = (rows as List)
        .map((row) => row['requester_id'] == myId ? row['addressee_id'] as String : row['requester_id'] as String)
        .toSet()
        .toList();

    return _fetchProfiles(otherIds);
  }

  Future<List<FriendshipRequest>> fetchIncomingRequests() async {
    final myId = _myId;
    final rows = await _client
        .from('friendships')
        .select('id, requester_id')
        .eq('status', 'pendente')
        .eq('addressee_id', myId);

    final requestRows = (rows as List).cast<Map<String, dynamic>>();
    final requesterIds = requestRows.map((row) => row['requester_id'] as String).toSet().toList();
    final profiles = {for (final p in await _fetchProfiles(requesterIds)) p.id: p};

    return requestRows
        .where((row) => profiles.containsKey(row['requester_id']))
        .map((row) => FriendshipRequest(
              friendshipId: row['id'] as String,
              profile: profiles[row['requester_id']]!,
            ))
        .toList();
  }

  Future<void> sendRequest(String toUserId) async {
    final myId = _myId;

    final existing = await _client
        .from('friendships')
        .select('id')
        .or('and(requester_id.eq.$myId,addressee_id.eq.$toUserId),'
            'and(requester_id.eq.$toUserId,addressee_id.eq.$myId)');

    if ((existing as List).isNotEmpty) {
      throw FriendshipAlreadyExistsException();
    }

    await _client.from('friendships').insert({
      'requester_id': myId,
      'addressee_id': toUserId,
      'status': 'pendente',
    });
  }

  /// Deletes the friendship row in whichever direction it exists —
  /// severs it regardless of who originally sent the request.
  Future<void> removeFriend(String friendId) async {
    final myId = _myId;
    await _client
        .from('friendships')
        .delete()
        .or('and(requester_id.eq.$myId,addressee_id.eq.$friendId),'
            'and(requester_id.eq.$friendId,addressee_id.eq.$myId)');
  }

  Future<void> respondToRequest(String friendshipId, {required bool accept}) async {
    if (accept) {
      await _client.from('friendships').update({'status': 'aceita'}).eq('id', friendshipId);
    } else {
      await _client.from('friendships').delete().eq('id', friendshipId);
    }
  }

  Future<List<UserProfile>> _fetchProfiles(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await _client.from('users').select().inFilter('id', ids);
    return (rows as List).map((row) => UserProfile.fromJson(row as Map<String, dynamic>)).toList();
  }
}
