/// Maps to `public.mimos`, with the parent folder's name/color embedded via
/// the Postgrest `folders(name, color)` select (see MimoRepository).
class Mimo {
  const Mimo({
    required this.id,
    required this.title,
    required this.priority,
    required this.purchaseStatus,
    required this.createdAt,
    this.folderId,
    this.folderName,
    this.folderColor,
    this.notes,
    this.coverImageUrl,
    this.originalUrl,
    this.storeDomain,
    this.price,
  });

  final String id;
  final String? folderId;
  final String? folderName;
  final String? folderColor;
  final String title;
  final String? notes;
  final String? coverImageUrl;
  final String? originalUrl;
  final String? storeDomain;
  final double? price;
  final String priority; // baixa | media | alta
  final String purchaseStatus; // desejado | comprado | arquivado
  final DateTime createdAt;

  /// The Feed's core rule: no folder => "Desorganizado"; otherwise the
  /// folder's own name/color replace that tag entirely.
  bool get isUnorganized => folderId == null;

  factory Mimo.fromJson(Map<String, dynamic> json) {
    final folder = json['folders'] as Map<String, dynamic>?;
    return Mimo(
      id: json['id'] as String,
      folderId: json['folder_id'] as String?,
      folderName: folder?['name'] as String?,
      folderColor: folder?['color'] as String?,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      originalUrl: json['original_url'] as String?,
      storeDomain: json['store_domain'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      priority: json['priority'] as String? ?? 'media',
      purchaseStatus: json['purchase_status'] as String? ?? 'desejado',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
