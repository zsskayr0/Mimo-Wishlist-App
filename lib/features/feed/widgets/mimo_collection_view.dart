import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/layout/mimo_view_mode.dart';
import '../../../core/layout/view_mode_controller.dart';
import '../../../core/theme/mimo_colors.dart';
import '../../../data/models/mimo.dart';
import 'mimo_card.dart';

String _formatPrice(double price) {
  final fixed = price.toStringAsFixed(2).replaceAll('.', ',');
  final parts = fixed.split(',');
  final intPart = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  return 'R\$ $intPart,${parts[1]}';
}

Color _colorFromHex(String hex) => Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

const _priorityLabels = {'baixa': 'Baixa', 'media': 'Média', 'alta': 'Alta'};
const _statusLabels = {'desejado': 'Desejado', 'comprado': 'Comprado', 'arquivado': 'Arquivado'};

Color _priorityColor(MimoColors colors, String priority) => switch (priority) {
      'alta' => colors.tagPlum,
      'media' => colors.tagGold,
      _ => colors.tagGray,
    };

Color _statusColor(MimoColors colors, String status) => switch (status) {
      'comprado' => colors.tagSage,
      'arquivado' => colors.tagGray,
      _ => colors.tagGold,
    };

/// Renders a mimo list per the view mode picked in Settings →
/// Visualização (mobile and desktop have their own, independent choice —
/// see `ViewModeController`). Handles scrolling itself (a `ListView` or
/// grid delegate is always the outermost scrollable here), so callers
/// just drop this in place of what used to be a bare grid.
class MimoCollectionView extends StatelessWidget {
  const MimoCollectionView({
    super.key,
    required this.mimos,
    required this.onTap,
    required this.isDesktop,
    this.padding = EdgeInsets.zero,
  });

  final List<Mimo> mimos;
  final ValueChanged<Mimo> onTap;
  final bool isDesktop;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return ValueListenableBuilder<DesktopMimoView>(
        valueListenable: ViewModeController.instance.desktopMode,
        builder: (context, mode, _) {
          return switch (mode) {
            DesktopMimoView.list => _MimoListView(mimos: mimos, onTap: onTap, detailed: false, padding: padding),
            DesktopMimoView.detailedList =>
              _MimoListView(mimos: mimos, onTap: onTap, detailed: true, padding: padding),
            DesktopMimoView.table => _MimoTableView(mimos: mimos, onTap: onTap, padding: padding),
            DesktopMimoView.dynamicGrid =>
              _MimoGridView(mimos: mimos, onTap: onTap, dynamicCover: true, padding: padding),
          };
        },
      );
    }
    return ValueListenableBuilder<MobileMimoView>(
      valueListenable: ViewModeController.instance.mobileMode,
      builder: (context, mode, _) {
        return switch (mode) {
          MobileMimoView.list => _MimoListView(mimos: mimos, onTap: onTap, detailed: false, padding: padding),
          MobileMimoView.detailedList => _MimoListView(mimos: mimos, onTap: onTap, detailed: true, padding: padding),
          MobileMimoView.grid2 => _MimoGridView(mimos: mimos, onTap: onTap, crossAxisCount: 2, padding: padding),
          MobileMimoView.grid3 => _MimoGridView(mimos: mimos, onTap: onTap, crossAxisCount: 3, padding: padding),
          MobileMimoView.grid4 => _MimoGridView(mimos: mimos, onTap: onTap, crossAxisCount: 4, padding: padding),
        };
      },
    );
  }
}

class _MimoGridView extends StatelessWidget {
  const _MimoGridView({
    required this.mimos,
    required this.onTap,
    this.dynamicCover = false,
    this.crossAxisCount,
    required this.padding,
  });

  final List<Mimo> mimos;
  final ValueChanged<Mimo> onTap;
  final bool dynamicCover;

  /// Fixed column count for mobile's grid2/3/4. Null uses the
  /// auto-columns-by-width delegate instead (desktop's dynamicGrid).
  final int? crossAxisCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (crossAxisCount != null) {
      return MasonryGridView.count(
        padding: padding,
        crossAxisCount: crossAxisCount!,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        itemCount: mimos.length,
        itemBuilder: (context, index) => MimoCard(
          mimo: mimos[index],
          onTap: () => onTap(mimos[index]),
          dynamicCover: dynamicCover,
        ),
      );
    }
    return MasonryGridView.extent(
      padding: padding,
      maxCrossAxisExtent: 190,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      itemCount: mimos.length,
      itemBuilder: (context, index) => MimoCard(
        mimo: mimos[index],
        onTap: () => onTap(mimos[index]),
        dynamicCover: dynamicCover,
      ),
    );
  }
}

class _MimoListView extends StatelessWidget {
  const _MimoListView({required this.mimos, required this.onTap, required this.detailed, required this.padding});

  final List<Mimo> mimos;
  final ValueChanged<Mimo> onTap;
  final bool detailed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: mimos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final mimo = mimos[index];
        return _MimoListTile(mimo: mimo, detailed: detailed, onTap: () => onTap(mimo));
      },
    );
  }
}

class _MimoListTile extends StatelessWidget {
  const _MimoListTile({required this.mimo, required this.detailed, required this.onTap});

  final Mimo mimo;
  final bool detailed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final folderColor = mimo.folderColor == null ? colors.tagGold : _colorFromHex(mimo.folderColor!);
    final thumbSize = detailed ? 68.0 : 48.0;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: thumbSize,
                  height: thumbSize,
                  child: mimo.coverImageUrl == null
                      ? Container(
                          color: colors.placeholder,
                          alignment: Alignment.center,
                          child: Icon(Icons.image_outlined, size: detailed ? 24 : 18, color: colors.inkFaint),
                        )
                      : Image.network(mimo.coverImageUrl!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mimo.title,
                      maxLines: detailed ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: detailed ? 14.5 : 13.5, fontWeight: FontWeight.bold),
                    ),
                    if (mimo.price != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        _formatPrice(mimo.price!),
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.inkSoft),
                      ),
                    ],
                    if (detailed) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Pill(
                            label: mimo.isUnorganized ? 'Desorganizado' : mimo.folderName ?? '—',
                            color: mimo.isUnorganized ? colors.tagGray : folderColor,
                            background: mimo.isUnorganized ? colors.tagGrayBg : folderColor.withValues(alpha: 0.16),
                          ),
                          for (final tag in mimo.tags.take(3))
                            _Pill(label: '#${tag.name}', color: colors.tagPlum, background: colors.tagPlumBg),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: colors.inkFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop-only "Tabela" — a real Notion-style data grid: aligned
/// columns, a light header row, thin row dividers instead of boxed
/// cells, and the default hover highlight `InkWell` already gives for
/// free when a mouse is present.
class _MimoTableView extends StatelessWidget {
  const _MimoTableView({required this.mimos, required this.onTap, required this.padding});

  final List<Mimo> mimos;
  final ValueChanged<Mimo> onTap;
  final EdgeInsetsGeometry padding;

  static const _titleFlex = 4;
  static const _priceFlex = 2;
  static const _folderFlex = 2;
  static const _tagsFlex = 3;
  static const _priorityFlex = 2;
  static const _statusFlex = 2;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Padding(
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _headerRow(colors),
            Divider(height: 1, color: colors.border),
            Expanded(
              child: ListView.separated(
                itemCount: mimos.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
                itemBuilder: (context, index) => _bodyRow(context, colors, mimos[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerRow(MimoColors colors) {
    Widget label(String text, int flex) => Expanded(
          flex: flex,
          child: Text(
            text,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: colors.inkFaint),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          const SizedBox(width: 34), // cover column
          const SizedBox(width: 12),
          label('TÍTULO', _titleFlex),
          label('PREÇO', _priceFlex),
          label('PASTA', _folderFlex),
          label('TAGS', _tagsFlex),
          label('PRIORIDADE', _priorityFlex),
          label('STATUS', _statusFlex),
        ],
      ),
    );
  }

  Widget _bodyRow(BuildContext context, MimoColors colors, Mimo mimo) {
    final folderColor = mimo.folderColor == null ? colors.tagGold : _colorFromHex(mimo.folderColor!);
    return InkWell(
      onTap: () => onTap(mimo),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                width: 34,
                height: 34,
                child: mimo.coverImageUrl == null
                    ? Container(color: colors.placeholder, child: Icon(Icons.image_outlined, size: 14, color: colors.inkFaint))
                    : Image.network(mimo.coverImageUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: _titleFlex,
              child: Text(
                mimo.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: _priceFlex,
              child: Text(
                mimo.price == null ? '—' : _formatPrice(mimo.price!),
                style: TextStyle(fontSize: 12.5, color: colors.inkSoft, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: _folderFlex,
              child: _Pill(
                label: mimo.isUnorganized ? 'Desorganizado' : (mimo.folderName ?? '—'),
                color: mimo.isUnorganized ? colors.tagGray : folderColor,
                background: mimo.isUnorganized ? colors.tagGrayBg : folderColor.withValues(alpha: 0.16),
                compact: true,
              ),
            ),
            Expanded(
              flex: _tagsFlex,
              child: mimo.tags.isEmpty
                  ? Text('—', style: TextStyle(fontSize: 12, color: colors.inkFaint))
                  : Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final tag in mimo.tags.take(2))
                          _Pill(label: '#${tag.name}', color: colors.tagPlum, background: colors.tagPlumBg, compact: true),
                        if (mimo.tags.length > 2)
                          Text('+${mimo.tags.length - 2}', style: TextStyle(fontSize: 11, color: colors.inkFaint)),
                      ],
                    ),
            ),
            Expanded(
              flex: _priorityFlex,
              child: _Pill(
                label: _priorityLabels[mimo.priority] ?? mimo.priority,
                color: _priorityColor(colors, mimo.priority),
                background: _priorityColor(colors, mimo.priority).withValues(alpha: 0.14),
                compact: true,
              ),
            ),
            Expanded(
              flex: _statusFlex,
              child: _Pill(
                label: _statusLabels[mimo.purchaseStatus] ?? mimo.purchaseStatus,
                color: _statusColor(colors, mimo.purchaseStatus),
                background: _statusColor(colors, mimo.purchaseStatus).withValues(alpha: 0.14),
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.background, this.compact = false});

  final String label;
  final Color color;
  final Color background;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: compact ? 10.5 : 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
