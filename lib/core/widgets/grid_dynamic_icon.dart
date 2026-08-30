import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The "cards adapt to each cover's real proportions" toggle icon — a 2x2
/// grid of rounded squares, from the exact SVG asset the reference gave.
/// `colorFilter` recolors it regardless of the fixed fill baked into the
/// SVG file, so it follows the surrounding button's selected/unselected
/// color like every other icon in this chip.
class GridDynamicIcon extends StatelessWidget {
  const GridDynamicIcon({super.key, required this.color, this.size = 14});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/grid_dynamic.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
