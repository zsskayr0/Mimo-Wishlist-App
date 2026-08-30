/// Maps to `public.folders`. `mimoCount` comes from the embedded
/// `mimos(count)` aggregate (see FolderRepository), not a real column.
class Folder {
  const Folder({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.color,
    required this.isShared,
    this.mimoCount = 0,
    this.ownerUsername,
  });

  final String id;
  final String ownerId;
  final String name;
  final String color;
  final bool isShared;
  final int mimoCount;

  /// Only populated when the query embeds `users(username)` — see
  /// `FolderRepository.fetchSharedWithMe`, which needs it to show "de
  /// @quemcompartilhou" on the Amigos screen.
  final String? ownerUsername;

  factory Folder.fromJson(Map<String, dynamic> json) {
    final mimos = json['mimos'] as List?;
    final count = mimos != null && mimos.isNotEmpty ? (mimos.first['count'] as num?)?.toInt() : null;
    final owner = json['users'] as Map<String, dynamic>?;
    return Folder(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      isShared: json['is_shared'] as bool? ?? false,
      mimoCount: count ?? 0,
      ownerUsername: owner?['username'] as String?,
    );
  }
}
