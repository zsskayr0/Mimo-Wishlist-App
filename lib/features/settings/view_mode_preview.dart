import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';

/// The shapes a preview can draw — one per view mode, but shared where
/// two modes look the same at this scale (grid2/grid3 only differ in
/// column count, so they share `grid`).
enum ViewModeShape { list, detailedList, grid, table, dynamicGrid }

/// A tiny animated mockup of what a view mode actually looks like —
/// blocks fade + scale in with a short stagger the moment this becomes
/// visible, "uma animação simples e fluida mostrando o que cada um faz."
/// Pure decoration: no data, no state that outlives one build of the
/// page it's on.
class ViewModePreview extends StatefulWidget {
  const ViewModePreview({super.key, required this.shape, this.columns = 2});

  final ViewModeShape shape;

  /// Only used by [ViewModeShape.grid] — how many columns to draw.
  final int columns;

  @override
  State<ViewModePreview> createState() => _ViewModePreviewState();
}

class _ViewModePreviewState extends State<ViewModePreview> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _stagger(int index, int count) {
    final start = (index / (count + 1)).clamp(0.0, 1.0);
    final end = (start + 0.6).clamp(0.0, 1.0);
    return CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeOutCubic));
  }

  Widget _piece(int index, int count, {required Widget child}) {
    final anim = _stagger(index, count);
    return FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.82, end: 1.0).animate(anim),
        child: child,
      ),
    );
  }

  Widget _bar(MimoColors colors, {double width = double.infinity, double height = 5, Color? color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color ?? colors.border, borderRadius: BorderRadius.circular(3)),
    );
  }

  Widget _block(MimoColors colors, {double? width, double? height, Color? color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? MimoColors.gradientA.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Container(
      width: 116,
      height: 80,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: switch (widget.shape) {
        ViewModeShape.list => _listPreview(colors, detailed: false),
        ViewModeShape.detailedList => _listPreview(colors, detailed: true),
        ViewModeShape.grid => _gridPreview(colors),
        ViewModeShape.table => _tablePreview(colors),
        ViewModeShape.dynamicGrid => _dynamicGridPreview(colors),
      },
    );
  }

  Widget _listPreview(MimoColors colors, {required bool detailed}) {
    final count = detailed ? 2 : 3;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < count; i++)
          _piece(
            i,
            count,
            child: Row(
              children: [
                _block(colors, width: detailed ? 18 : 12, height: detailed ? 18 : 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _bar(colors, color: MimoColors.gradientA.withValues(alpha: 0.55)),
                      const SizedBox(height: 4),
                      _bar(colors, width: 26),
                      if (detailed) ...[
                        const SizedBox(height: 4),
                        _bar(colors, width: 16, height: 4, color: colors.tagPlum.withValues(alpha: 0.5)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _gridPreview(MimoColors colors) {
    final columns = widget.columns;
    final rows = columns >= 3 ? 2 : 2;
    final count = columns * rows;
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      children: [
        for (var i = 0; i < count; i++)
          _piece(i, count, child: _block(colors, color: MimoColors.gradientA.withValues(alpha: 0.22 + (i % 3) * 0.08))),
      ],
    );
  }

  /// Uneven block heights (not a uniform grid) — the whole point of this
  /// mode is covers that keep their own proportions instead of a forced
  /// square, so the preview has to actually look uneven to mean anything.
  Widget _dynamicGridPreview(MimoColors colors) {
    const leftHeights = [30.0, 18.0];
    const rightHeights = [16.0, 32.0];
    Widget column(List<double> heights, int startIndex) {
      return Expanded(
        child: Column(
          children: [
            for (var i = 0; i < heights.length; i++) ...[
              if (i > 0) const SizedBox(height: 5),
              _piece(startIndex + i, 4, child: _block(colors, width: double.infinity, height: heights[i])),
            ],
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        column(leftHeights, 0),
        const SizedBox(width: 5),
        column(rightHeights, 2),
      ],
    );
  }

  Widget _tablePreview(MimoColors colors) {
    const rowCount = 3;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _piece(0, rowCount + 1, child: Row(children: [_bar(colors, width: 20), const Spacer(), _bar(colors, width: 20)])),
        const SizedBox(height: 4),
        Divider(height: 1, color: colors.border),
        const SizedBox(height: 4),
        for (var i = 0; i < rowCount; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          _piece(
            i + 1,
            rowCount + 1,
            child: Row(
              children: [
                _block(colors, width: 8, height: 8),
                const SizedBox(width: 6),
                Expanded(child: _bar(colors, color: MimoColors.gradientA.withValues(alpha: 0.45))),
                const SizedBox(width: 6),
                _bar(colors, width: 14),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
