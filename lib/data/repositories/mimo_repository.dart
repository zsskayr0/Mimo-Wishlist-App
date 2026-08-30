import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mimo.dart';

/// Talks to `public.mimos`. RLS does the actual access control — this class
/// just shapes the queries; it never needs to check ownership itself.
class MimoRepository {
  MimoRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Pulls the folder name/color and this mimo's tags in the same round
  /// trip — the search/filter system works against an already-fetched
  /// list, so every mimo needs its tags up front, not on demand.
  static const _selectWithRelations = '*, folders(name, color), mimo_tags(tags(id, name, color, is_system))';

  Future<List<Mimo>> fetchFeed() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final rows = await _client
        .from('mimos')
        .select(_selectWithRelations)
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
        .select(_selectWithRelations)
        .eq('folder_id', folderId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Mimo.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Mimo?> fetchById(String mimoId) async {
    final rows = await _client
        .from('mimos')
        .select(_selectWithRelations)
        .eq('id', mimoId)
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : Mimo.fromJson(list.first as Map<String, dynamic>);
  }

  /// Files an existing mimo into (or out of, when [folderId] is null) a
  /// folder. Never a second row: this UPDATEs `mimos.folder_id` in place,
  /// which is the whole "one folder per mimo" rule.
  Future<void> assignFolder(String mimoId, String? folderId) async {
    await _client.from('mimos').update({'folder_id': folderId}).eq('id', mimoId);
  }

  Future<void> updatePriority(String mimoId, String priority) async {
    await _client.from('mimos').update({'priority': priority}).eq('id', mimoId);
  }

  Future<void> updatePurchaseStatus(String mimoId, String status) async {
    await _client.from('mimos').update({'purchase_status': status}).eq('id', mimoId);
  }

  Future<void> updateNotes(String mimoId, String? notes) async {
    await _client.from('mimos').update({'notes': notes}).eq('id', mimoId);
  }

  Future<void> deleteMimo(String mimoId) async {
    await _client.from('mimos').delete().eq('id', mimoId);
  }

  /// Manual quick-capture: paste-a-link path from the wireframes. Cover
  /// image / AI category+crop suggestions are a later increment — this
  /// inserts with `source: manual`, and no folder means it lands in the
  /// Feed tagged "Desorganizado" until the user files it, per the product
  /// rule. Returns the new row's id so the caller can attach tags.
  Future<String> createMimo({
    required String title,
    String? originalUrl,
    String? storeDomain,
    String? coverImageUrl,
    double? price,
    String priority = 'media',
    String? folderId,
    List<String> tagIds = const [],
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('createMimo called with no signed-in user');
    }

    final inserted = await _client
        .from('mimos')
        .insert({
          'owner_id': userId,
          'title': title,
          'original_url': originalUrl,
          'store_domain': storeDomain,
          'cover_image_url': coverImageUrl,
          'price': price,
          'priority': priority,
          'folder_id': folderId,
          'source': 'manual',
        })
        .select('id')
        .single();
    final mimoId = inserted['id'] as String;

    if (tagIds.isNotEmpty) {
      await _client.from('mimo_tags').insert([
        for (final tagId in tagIds) {'mimo_id': mimoId, 'tag_id': tagId},
      ]);
    }

    return mimoId;
  }

  Future<void> updateMimo({
    required String mimoId,
    required String title,
    String? originalUrl,
    String? storeDomain,
    String? coverImageUrl,
    double? price,
    required String priority,
    String? folderId,
    required List<String> tagIds,
  }) async {
    await _client.from('mimos').update({
      'title': title,
      'original_url': originalUrl,
      'store_domain': storeDomain,
      'cover_image_url': coverImageUrl,
      'price': price,
      'priority': priority,
      'folder_id': folderId,
    }).eq('id', mimoId);

    // Simplest correct way to reconcile the tag set: clear and re-insert
    // the current selection, rather than diffing adds/removes.
    await _client.from('mimo_tags').delete().eq('mimo_id', mimoId);
    if (tagIds.isNotEmpty) {
      await _client.from('mimo_tags').insert([
        for (final tagId in tagIds) {'mimo_id': mimoId, 'tag_id': tagId},
      ]);
    }
  }

  /// "Duplicar em outra pasta" — a mimo has at most one folder, so putting
  /// it in a second one is a brand-new row, never a reassignment of the
  /// original. Copies the fields that make sense to carry over; tags are
  /// left for the user to redo on the copy.
  Future<String> duplicateToFolder(Mimo mimo, String? folderId) {
    return createMimo(
      title: mimo.title,
      originalUrl: mimo.originalUrl,
      storeDomain: mimo.storeDomain,
      coverImageUrl: mimo.coverImageUrl,
      price: mimo.price,
      priority: mimo.priority,
      folderId: folderId,
    );
  }
}
