import 'package:flutter/material.dart';

/// The Mimo brand mark — a tag shape with a punched hole, painted
/// directly (not an SVG asset) so it scales crisply at any size with one
/// reusable widget and no asset-loading/parsing. Same path as the app's
/// launcher icon; see tool/generate_icons.dart for how it was derived
/// from the official brand SVG. The mark has generous padding baked into
/// its own 64-unit coordinate space, so [size] should match the space
/// it's meant to fill (e.g. the gradient tile around it), not be given
/// extra shrinkage on top — that's how the official "app icon" treatment
/// looks (mark nearly filling its tile).
class MimoMark extends StatelessWidget {
  const MimoMark({super.key, this.size = 24, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _MimoMarkPainter(color));
  }
}

class _MimoMarkPainter extends CustomPainter {
  _MimoMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    // M34.5 6H50a8 8 0 0 1 8 8v15.5a8 8 0 0 1-2.34 5.66L34.16 56.66
    // a8 8 0 0 1-11.31 0L7.34 41.15a8 8 0 0 1 0-11.31L28.84 8.34
    // A8 8 0 0 1 34.5 6Z — sweep-flag 1 maps to arcToPoint's clockwise: true.
    final mark = Path()
      ..moveTo(34.5, 6)
      ..lineTo(50, 6)
      ..arcToPoint(const Offset(58, 14), radius: const Radius.circular(8))
      ..lineTo(58, 29.5)
      ..arcToPoint(const Offset(55.66, 35.16), radius: const Radius.circular(8))
      ..lineTo(34.16, 56.66)
      ..arcToPoint(const Offset(22.85, 56.66), radius: const Radius.circular(8))
      ..lineTo(7.34, 41.15)
      ..arcToPoint(const Offset(7.34, 29.84), radius: const Radius.circular(8))
      ..lineTo(28.84, 8.34)
      ..arcToPoint(const Offset(34.5, 6), radius: const Radius.circular(8))
      ..close();
    final hole = Path()..addOval(Rect.fromCircle(center: const Offset(45, 19), radius: 5.2));
    final glyph = Path.combine(PathOperation.difference, mark, hole);
    canvas.drawPath(glyph, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MimoMarkPainter oldDelegate) => oldDelegate.color != color;
}
