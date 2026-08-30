import 'package:flutter/material.dart';

import '../../../core/theme/mimo_colors.dart';
import '../../../data/models/mimo.dart';

/// One masonry-grid card (see FeedScreen/FolderDetailScreen's
/// `MasonryGridView.extent`). The Desorganizado/Pasta pill is mutually
/// exclusive by construction — it reads straight off [Mimo.isUnorganized],
/// never both.
///
/// The cover is a true 1:1 `AspectRatio` by default — mimo covers are meant
/// to be square (the blueprint's "recorte 1x1" rule; see the real crop step
/// in the capture sheet) — unless [dynamicCover] is on, the Feed's
/// "cards adapt to the image" toggle, which lets each cover keep its own
/// natural proportions instead. Everything below the cover sizes to its own
/// content (`mainAxisSize.min`), never to a fixed cell height — a plain
/// `GridView` forces every cell to the same `childAspectRatio`, which left
/// a gap of blank space under the pill on any card shorter than the
/// tallest one on screen; the masonry grid lets each card be exactly as
/// tall as it needs to be.
class MimoCard extends StatelessWidget {
  const MimoCard({super.key, required this.mimo, this.onTap, this.dynamicCover = false});

  final Mimo mimo;
  final VoidCallback? onTap;

  /// When true and the mimo has a cover, the image keeps its real aspect
  /// ratio instead of being forced into a 1:1 box.
  final bool dynamicCover;

  String _formatPrice(double price) {
    final fixed = price.toStringAsFixed(2).replaceAll('.', ',');
    final parts = fixed.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }

  Color _folderColor(MimoColors colors) {
    final hex = mimo.folderColor;
    if (hex == null) return colors.tagGold;
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  Widget _cover(MimoColors colors) {
    final hasImage = mimo.coverImageUrl != null;

    // No image to take a ratio from, or the toggle is off — square,
    // as always.
    if (!dynamicCover || !hasImage) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          width: double.infinity,
          color: colors.placeholder,
          alignment: Alignment.center,
          child: !hasImage
              ? Icon(Icons.image_outlined, color: colors.inkFaint.withValues(alpha: 0.8), size: 30)
              : Image.network(mimo.coverImageUrl!, fit: BoxFit.cover),
        ),
      );
    }

    // Dynamic: no AspectRatio wrapper — an explicit `width` with no
    // `height` on Image.network makes it size itself to the image's own
    // aspect ratio scaled to the card's width, once the image loads.
    return Container(
      color: colors.placeholder,
      child: Image.network(mimo.coverImageUrl!, width: double.infinity, fit: BoxFit.fitWidth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final folderColor = _folderColor(colors);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            // The masonry grid gives this card an unbounded height (that's
            // how it lets each card be its own natural height) — mainAxisSize
            // must be `min` here or a `max` Column would try to fill that
            // unbounded space and blow up.
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cover(colors),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mimo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, height: 1.25),
                    ),
                    if (mimo.price != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatPrice(mimo.price!),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.inkSoft),
                      ),
                    ],
                    const SizedBox(height: 6),
                    _StatusPill(
                      label: mimo.isUnorganized ? 'Desorganizado' : 'Pasta: ${mimo.folderName ?? '—'}',
                      color: mimo.isUnorganized ? colors.tagGray : folderColor,
                      background: mimo.isUnorganized ? colors.tagGrayBg : folderColor.withValues(alpha: 0.16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
