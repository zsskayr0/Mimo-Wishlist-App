import '../models/mimo.dart';

enum MimoSortBy { dateAdded, price }

/// Everything the filter sheet can set, plus the free-text search box.
/// Applied client-side (`apply`) against an already-fetched list — simple,
/// and plenty fast at the scale a personal wishlist actually reaches.
class MimoFilters {
  const MimoFilters({
    this.searchQuery = '',
    this.tagIds = const {},
    this.folderId,
    this.unorganizedOnly = false,
    this.ownerId,
    this.priority,
    this.purchaseStatus,
    this.storeDomain,
    this.sortBy = MimoSortBy.dateAdded,
    this.sortDescending = true,
  });

  final String searchQuery;
  final Set<String> tagIds;
  final String? folderId;

  /// "Pasta: Desorganizado" — mutually exclusive with [folderId] by
  /// construction (the sheet clears one whenever it sets the other);
  /// distinct from "no pasta filter at all" (`folderId == null &&
  /// !unorganizedOnly`), which `folderId` alone can't express since a
  /// null folderId already means "don't filter by folder".
  final bool unorganizedOnly;
  final String? ownerId;
  final String? priority;
  final String? purchaseStatus;
  final String? storeDomain;
  final MimoSortBy sortBy;
  final bool sortDescending;

  bool get hasActiveFilters =>
      tagIds.isNotEmpty ||
      folderId != null ||
      unorganizedOnly ||
      ownerId != null ||
      priority != null ||
      purchaseStatus != null ||
      storeDomain != null;

  int get activeCount => [
        if (tagIds.isNotEmpty) 1,
        if (folderId != null || unorganizedOnly) 1,
        if (ownerId != null) 1,
        if (priority != null) 1,
        if (purchaseStatus != null) 1,
        if (storeDomain != null) 1,
      ].length;

  MimoFilters copyWith({
    String? searchQuery,
    Set<String>? tagIds,
    String? Function()? folderId,
    bool? unorganizedOnly,
    String? Function()? ownerId,
    String? Function()? priority,
    String? Function()? purchaseStatus,
    String? Function()? storeDomain,
    MimoSortBy? sortBy,
    bool? sortDescending,
  }) {
    return MimoFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      tagIds: tagIds ?? this.tagIds,
      folderId: folderId != null ? folderId() : this.folderId,
      unorganizedOnly: unorganizedOnly ?? this.unorganizedOnly,
      ownerId: ownerId != null ? ownerId() : this.ownerId,
      priority: priority != null ? priority() : this.priority,
      purchaseStatus: purchaseStatus != null ? purchaseStatus() : this.purchaseStatus,
      storeDomain: storeDomain != null ? storeDomain() : this.storeDomain,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  static const empty = MimoFilters();

  /// Search matches the title OR any tag name — "quero que a pesquisa
  /// consiga pesquisar tags também".
  List<Mimo> apply(List<Mimo> mimos) {
    final query = searchQuery.trim().toLowerCase();

    var result = mimos.where((mimo) {
      if (query.isNotEmpty) {
        final titleMatches = mimo.title.toLowerCase().contains(query);
        final tagMatches = mimo.tags.any((tag) => tag.name.toLowerCase().contains(query));
        if (!titleMatches && !tagMatches) return false;
      }
      if (tagIds.isNotEmpty && !mimo.tags.any((tag) => tagIds.contains(tag.id))) return false;
      if (unorganizedOnly && mimo.folderId != null) return false;
      if (folderId != null && mimo.folderId != folderId) return false;
      if (ownerId != null && mimo.ownerId != ownerId) return false;
      if (priority != null && mimo.priority != priority) return false;
      if (purchaseStatus != null && mimo.purchaseStatus != purchaseStatus) return false;
      if (storeDomain != null && mimo.storeDomain != storeDomain) return false;
      return true;
    }).toList();

    result.sort((a, b) {
      final int comparison = switch (sortBy) {
        MimoSortBy.dateAdded => a.createdAt.compareTo(b.createdAt),
        MimoSortBy.price => (a.price ?? 0).compareTo(b.price ?? 0),
      };
      return sortDescending ? -comparison : comparison;
    });

    return result;
  }
}
