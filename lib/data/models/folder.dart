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
    this.memberAvatarUrls = const [],
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

  /// One entry per member (owner not included), null where that member
  /// has no avatar set — only populated when the query embeds
  /// `folder_members(users(avatar_url))`, for the Pastas list's
  /// overlapping-avatars stack on shared folders.
  final List<String?> memberAvatarUrls;

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
      ownerUsername: owner?['username'] as String?,
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
