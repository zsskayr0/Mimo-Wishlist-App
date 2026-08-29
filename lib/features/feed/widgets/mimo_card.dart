import 'package:flutter/material.dart';

import '../../../core/theme/mimo_colors.dart';
import '../../../data/models/mimo.dart';

/// One grid card. The Desorganizado/Pasta pill is mutually exclusive by
/// construction — it reads straight off [Mimo.isUnorganized], never both.
class MimoCard extends StatelessWidget {
  const MimoCard({super.key, required this.mimo});

  final Mimo mimo;

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

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final folderColor = _folderColor(colors);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: Container(
              color: colors.placeholder,
              alignment: Alignment.center,
              child: mimo.coverImageUrl == null
                  ? Icon(Icons.image_outlined, color: colors.inkFaint.withValues(alpha: 0.8), size: 30)
                  : Image.network(mimo.coverImageUrl!, fit: BoxFit.cover),
            ),
          ),
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
