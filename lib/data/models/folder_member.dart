/// One row of `public.folder_members`, joined with the member's profile
/// — or, for the synthetic entry FolderDetailScreen/FolderOptionsSheet
/// prepend, the folder's owner (role `'dono'`, not a real DB value —
/// the owner is `folders.owner_id`, never an actual folder_members row).
class FolderMember {
  const FolderMember({
    required this.userId,
    required this.username,
    required this.role,
    this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String role; // dono | editor | visualizador

  bool get isOwner => role == 'dono';

  factory FolderMember.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>;
    return FolderMember(
      userId: user['id'] as String,
      username: user['username'] as String,
      displayName: user['display_name'] as String?,
      avatarUrl: user['avatar_url'] as String?,
      role: json['role'] as String,
    );
  }
}
