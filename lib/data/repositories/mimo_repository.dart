import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mimo.dart';

/// Talks to `public.mimos`. RLS does the actual access control — this class
/// just shapes the queries; it never needs to check ownership itself.
class MimoRepository {
  MimoRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Mimo>> fetchFeed() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final rows = await _client
        .from('mimos')
        .select('*, folders(name, color)')
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Mimo.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// All mimos filed under one folder — from every member with access to
  /// it, not just the caller, since a shared folder is meant as a joint
  /// view. RLS (`mimos_select`) is what actually enforces who gets to see
  /// what here.
  Future<List<Mimo>> fetchByFolder(String folderId) async {
    final rows = await _client
        .from('mimos')
        .select('*, folders(name, color)')
        .eq('folder_id', folderId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Mimo.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Files an existing mimo into (or out of, when [folderId] is null) a
  /// folder. Never a second row: this UPDATEs `mimos.folder_id` in place,
  /// which is the whole "one folder per mimo" rule.
  Future<void> assignFolder(String mimoId, String? folderId) async {
    await _client.from('mimos').update({'folder_id': folderId}).eq('id', mimoId);
  }

  /// Manual quick-capture: paste-a-link path from the wireframes. Cover
  /// image / AI category+crop suggestions are a later increment — this
  /// inserts with `source: manual` and no folder, so it lands in the Feed
  /// tagged "Desorganizado" until the user files it, per the product rule.
  Future<void> createMimo({
    required String title,
    String? originalUrl,
    String? storeDomain,
    double? price,
    String priority = 'media',
    String? folderId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('createMimo called with no signed-in user');
    }

    await _client.from('mimos').insert({
      'owner_id': userId,
      'title': title,
      'original_url': originalUrl,
      'store_domain': storeDomain,
      'price': price,
      'priority': priority,
      'folder_id': folderId,
      'source': 'manual',
    });
  }
}
