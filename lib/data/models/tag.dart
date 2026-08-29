/// Maps to `public.tags`. `owner_id` null in the row means a predefined
/// system tag (`isSystem = true`), shared by every user.
class MimoTag {
  const MimoTag({required this.id, required this.name, required this.color, required this.isSystem});

  final String id;
  final String name;
  final String color;
  final bool isSystem;

  factory MimoTag.fromJson(Map<String, dynamic> json) => MimoTag(
        id: json['id'] as String,
        name: json['name'] as String,
        color: json['color'] as String,
        isSystem: json['is_system'] as bool? ?? false,
      );
}
