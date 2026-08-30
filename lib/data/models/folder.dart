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
    this.coverImageUrl,
    this.ownerUsername,
    this.ownerDisplayName,
    this.ownerAvatarUrl,
    this.memberAvatarUrls = const [],
  });

  final String id;
  final String ownerId;
  final String name;
  final String color;
  final bool isShared;
  final int mimoCount;
  final String? coverImageUrl;

  /// Only populated when the query embeds
  /// `users!folders_owner_id_fkey(...)` — see FolderRepository, which
  /// always does now (needed for the "de @quemcompartilhou" line on
  /// Amigos and the owner's row in FolderOptionsSheet's member list).
  final String? ownerUsername;
  final String? ownerDisplayName;
  final String? ownerAvatarUrl;

  /// One entry per member (owner not included), null where that member
  /// has no avatar set — only populated when the query embeds
  /// `folder_members(users(avatar_url))`, for the Pastas list's
  /// overlapping-avatars stack on shared folders.
  final List<String?> memberAvatarUrls;

  Folder copyWith({
    String? name,
    String? color,
    String? Function()? coverImageUrl,
  }) {
    return Folder(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      color: color ?? this.color,
      isShared: isShared,
      mimoCount: mimoCount,
      coverImageUrl: coverImageUrl != null
          ? coverImageUrl()
          : this.coverImageUrl,
      ownerUsername: ownerUsername,
      ownerDisplayName: ownerDisplayName,
      ownerAvatarUrl: ownerAvatarUrl,
      memberAvatarUrls: memberAvatarUrls,
    );
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    final mimos = json['mimos'] as List?;
    final count = mimos != null && mimos.isNotEmpty
        ? (mimos.first['count'] as num?)?.toInt()
        : null;
    final owner = json['users'] as Map<String, dynamic>?;
    final members = json['folder_members'] as List?;
    return Folder(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      isShared: json['is_shared'] as bool? ?? false,
      mimoCount: count ?? 0,
      coverImageUrl: json['cover_image_url'] as String?,
      ownerUsername: owner?['username'] as String?,
      ownerDisplayName: owner?['display_name'] as String?,
      ownerAvatarUrl: owner?['avatar_url'] as String?,
      memberAvatarUrls: members == null
          ? const []
          : members
                .map(
                  (m) =>
                      ((m as Map<String, dynamic>)['users']
                              as Map<String, dynamic>?)?['avatar_url']
                          as String?,
                )
                .toList(),
    );
  }
}
