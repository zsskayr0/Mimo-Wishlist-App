/// One row of `public.folder_members`, joined with the member's profile.
class FolderMember {
  const FolderMember({
    required this.userId,
    required this.username,
    required this.role,
    this.displayName,
  });

  final String userId;
  final String username;
  final String? displayName;
  final String role; // editor | visualizador

  factory FolderMember.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>;
    return FolderMember(
      userId: user['id'] as String,
      username: user['username'] as String,
      displayName: user['display_name'] as String?,
      role: json['role'] as String,
    );
  }
}
