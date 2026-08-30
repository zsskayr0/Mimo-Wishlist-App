import 'tag.dart';

/// Maps to `public.mimos`, with the parent folder's name/color and this
/// mimo's tags embedded via the Postgrest select in MimoRepository
/// (`folders(name, color)`, `mimo_tags(tags(...))`) — one round trip
/// instead of N+1 queries, which is what the search/filter system needs
/// to work against an already-fetched list.
class Mimo {
  const Mimo({
    required this.id,
    required this.ownerId,
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
    this.tags = const [],
  });

  final String id;
  final String ownerId;
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
  final List<MimoTag> tags;

  /// The Feed's core rule: no folder => "Desorganizado"; otherwise the
  /// folder's own name/color replace that tag entirely.
  bool get isUnorganized => folderId == null;

  /// Only the fields that get edited in place after the initial fetch
  /// (priority/status from Detail or the table's inline pickers, notes
  /// from Detail) — `notes` uses the nullable-clearing-function pattern
  /// so callers can distinguish "leave it" from "clear it".
  Mimo copyWith({String? priority, String? purchaseStatus, String? Function()? notes}) {
    return Mimo(
      id: id,
      ownerId: ownerId,
      folderId: folderId,
      folderName: folderName,
      folderColor: folderColor,
      title: title,
      notes: notes != null ? notes() : this.notes,
      coverImageUrl: coverImageUrl,
      originalUrl: originalUrl,
      storeDomain: storeDomain,
      price: price,
      priority: priority ?? this.priority,
      purchaseStatus: purchaseStatus ?? this.purchaseStatus,
      createdAt: createdAt,
      tags: tags,
    );
  }

  factory Mimo.fromJson(Map<String, dynamic> json) {
    final folder = json['folders'] as Map<String, dynamic>?;
    final tagRows = json['mimo_tags'] as List?;

    return Mimo(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
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
      tags: tagRows == null
          ? const []
          : tagRows
              .map((row) => MimoTag.fromJson((row as Map<String, dynamic>)['tags'] as Map<String, dynamic>))
              .toList(),
    );
  }
}
