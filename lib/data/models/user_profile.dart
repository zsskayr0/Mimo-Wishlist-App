/// Maps to `public.users` — the public-profile side of an account.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  /// Up to 50 characters, shown under the username on Perfil.
  final String? bio;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
      );
}

/// One `friendships` row, paired with whichever profile is "the other side"
/// of it from the current user's point of view — see FriendshipRepository.
class FriendshipRequest {
  const FriendshipRequest({required this.friendshipId, required this.profile});

  final String friendshipId;
  final UserProfile profile;
}
