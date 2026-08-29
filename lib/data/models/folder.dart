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
  });

  final String id;
  final String ownerId;
  final String name;
  final String color;
  final bool isShared;
  final int mimoCount;

  factory Folder.fromJson(Map<String, dynamic> json) {
    final mimos = json['mimos'] as List?;
    final count = mimos != null && mimos.isNotEmpty ? (mimos.first['count'] as num?)?.toInt() : null;
    return Folder(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      isShared: json['is_shared'] as bool? ?? false,
      mimoCount: count ?? 0,
    );
  }
}
