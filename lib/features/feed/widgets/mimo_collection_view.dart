import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:url_launcher/url_launcher.dart';

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

// Shared between the table's header and body rows so their columns stay
// aligned.
const _tableColumnGap = SizedBox(width: 18);
const _tableCoverSize = 34.0;
const _tableLinkWidth = 96.0; // fixed, not flexed — a long domain shouldn't
// squeeze every other column ("um width fixo, pra não embolar muito").
const _tableTitleFlex = 4;
const _tablePriceFlex = 2;
const _tableFolderFlex = 2;
const _tableTagsFlex = 3;
const _tablePriorityFlex = 2;
const _tableStatusFlex = 2;

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
    this.onPriorityChanged,
    this.onStatusChanged,
    this.onCreateInline,
  });

  final List<Mimo> mimos;
  final ValueChanged<Mimo> onTap;
  final bool isDesktop;
  final EdgeInsets padding;

  /// Table mode only — lets priority/status be edited straight from the
  /// row instead of having to open the mimo first. Null in every other
  /// mode (list/grid rows don't have room for it, and the whole card is
  /// already just a shortcut to the same editors in Detail).
  final void Function(Mimo mimo, String priority)? onPriorityChanged;
  final void Function(Mimo mimo, String status)? onStatusChanged;

  /// Table mode only — the blank row at the bottom ("quero que fique
  /// umas linhas em branco para eu poder criar por lá mesmo"). Null
  /// hides that row entirely.
  final ValueChanged<String>? onCreateInline;

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
            DesktopMimoView.table => _MimoTableView(
                mimos: mimos,
                onTap: onTap,
                padding: padding,
                onPriorityChanged: onPriorityChanged,
                onStatusChanged: onStatusChanged,
                onCreateInline: onCreateInline,
              ),
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
  final EdgeInsets padding;

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
  final EdgeInsets padding;

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

/// Desktop-only "Tabela" — aligned columns, a header row, thin dividers
/// between rows. Sits directly on the page (no card frame around it —
/// "a impressão que dá é que ela está em um card", which wasn't the
/// intent); the row list is the one real scrollable, so nothing gets
/// clipped short at the bottom the way a bounded card would.
class _MimoTableView extends StatelessWidget {
  const _MimoTableView({
    required this.mimos,
    required this.onTap,
    required this.padding,
    this.onPriorityChanged,
    this.onStatusChanged,
    this.onCreateInline,
  });

  final List<Mimo> mimos;
  final ValueChanged<Mimo> onTap;
  final EdgeInsets padding;
  final void Function(Mimo mimo, String priority)? onPriorityChanged;
  final void Function(Mimo mimo, String status)? onStatusChanged;
  final ValueChanged<String>? onCreateInline;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final horizontal = EdgeInsets.only(left: padding.left, right: padding.right);
    return Column(
      children: [
        Padding(
          padding: horizontal.copyWith(top: padding.top),
          child: _headerRow(colors),
        ),
        Divider(height: 1, color: colors.border),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.only(bottom: padding.bottom),
            itemCount: mimos.length + (onCreateInline == null ? 0 : 1),
            separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
            itemBuilder: (context, index) {
              if (index >= mimos.length) {
                return Padding(
                  padding: horizontal,
                  child: _InlineCreateRow(onCreate: onCreateInline!),
                );
              }
              final mimo = mimos[index];
              return Padding(
                padding: horizontal,
                child: _TableRow(
                  mimo: mimo,
                  colors: colors,
                  onTap: () => onTap(mimo),
                  onPriorityChanged: onPriorityChanged == null ? null : (p) => onPriorityChanged!(mimo, p),
                  onStatusChanged: onStatusChanged == null ? null : (s) => onStatusChanged!(mimo, s),
                ),
              );
            },
          ),
        ),
      ],
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
    Widget fixedLabel(String text, double width) => SizedBox(
          width: width,
          child: Text(
            text,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: colors.inkFaint),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: _tableCoverSize),
          _tableColumnGap,
          label('TÍTULO', _tableTitleFlex),
          _tableColumnGap,
          fixedLabel('LINK', _tableLinkWidth),
          _tableColumnGap,
          label('PREÇO', _tablePriceFlex),
          _tableColumnGap,
          label('PASTA', _tableFolderFlex),
          _tableColumnGap,
          label('TAGS', _tableTagsFlex),
          _tableColumnGap,
          label('PRIORIDADE', _tablePriorityFlex),
          _tableColumnGap,
          label('STATUS', _tableStatusFlex),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.mimo,
    required this.colors,
    required this.onTap,
    this.onPriorityChanged,
    this.onStatusChanged,
  });

  final Mimo mimo;
  final MimoColors colors;
  final VoidCallback onTap;
  final ValueChanged<String>? onPriorityChanged;
  final ValueChanged<String>? onStatusChanged;

  Future<void> _openLink() async {
    final url = mimo.originalUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final folderColor = mimo.folderColor == null ? colors.tagGold : _colorFromHex(mimo.folderColor!);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Only the cover opens Detail — "quero que isso só aconteça
          // quando eu clicar na foto do item". Everything else in the row
          // either does nothing or (priority/status) edits in place.
          InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                width: _tableCoverSize,
                height: _tableCoverSize,
                child: mimo.coverImageUrl == null
                    ? Container(color: colors.placeholder, child: Icon(Icons.image_outlined, size: 14, color: colors.inkFaint))
                    : Image.network(mimo.coverImageUrl!, fit: BoxFit.cover),
              ),
            ),
          ),
          _tableColumnGap,
          Expanded(
            flex: _tableTitleFlex,
            child: Text(
              mimo.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          _tableColumnGap,
          SizedBox(
            width: _tableLinkWidth,
            child: mimo.storeDomain == null
                ? Text('—', style: TextStyle(fontSize: 12, color: colors.inkFaint))
                : InkWell(
                    onTap: mimo.originalUrl == null ? null : _openLink,
                    child: Text(
                      mimo.storeDomain!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MimoColors.gradientA),
                    ),
                  ),
          ),
          _tableColumnGap,
          Expanded(
            flex: _tablePriceFlex,
            child: Text(
              mimo.price == null ? '—' : _formatPrice(mimo.price!),
              style: TextStyle(fontSize: 12.5, color: colors.inkSoft, fontWeight: FontWeight.w600),
            ),
          ),
          _tableColumnGap,
          Expanded(
            flex: _tableFolderFlex,
            child: _Pill(
              label: mimo.isUnorganized ? 'Desorganizado' : (mimo.folderName ?? '—'),
              color: mimo.isUnorganized ? colors.tagGray : folderColor,
              background: mimo.isUnorganized ? colors.tagGrayBg : folderColor.withValues(alpha: 0.16),
              compact: true,
            ),
          ),
          _tableColumnGap,
          Expanded(
            flex: _tableTagsFlex,
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
          _tableColumnGap,
          Expanded(
            flex: _tablePriorityFlex,
            child: _EditablePill(
              label: _priorityLabels[mimo.priority] ?? mimo.priority,
              color: _priorityColor(colors, mimo.priority),
              background: _priorityColor(colors, mimo.priority).withValues(alpha: 0.14),
              options: _priorityLabels,
              current: mimo.priority,
              onChanged: onPriorityChanged,
            ),
          ),
          _tableColumnGap,
          Expanded(
            flex: _tableStatusFlex,
            child: _EditablePill(
              label: _statusLabels[mimo.purchaseStatus] ?? mimo.purchaseStatus,
              color: _statusColor(colors, mimo.purchaseStatus),
              background: _statusColor(colors, mimo.purchaseStatus).withValues(alpha: 0.14),
              options: _statusLabels,
              current: mimo.purchaseStatus,
              onChanged: onStatusChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// The blank row at the end of the table — type a title and hit enter to
/// create a mimo right there, no need to open the full capture sheet.
/// Everything else about it (folder, price, tags...) can be filled in
/// afterward the same way any other row's fields get edited.
class _InlineCreateRow extends StatefulWidget {
  const _InlineCreateRow({required this.onCreate});

  final ValueChanged<String> onCreate;

  @override
  State<_InlineCreateRow> createState() => _InlineCreateRowState();
}

class _InlineCreateRowState extends State<_InlineCreateRow> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    widget.onCreate(title);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: _tableCoverSize,
            height: _tableCoverSize,
            decoration: BoxDecoration(
              border: Border.all(color: colors.border, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(Icons.add, size: 15, color: colors.inkFaint),
          ),
          _tableColumnGap,
          Expanded(
            flex: _tableTitleFlex,
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Adicionar mimo…',
                hintStyle: TextStyle(color: colors.inkFaint, fontWeight: FontWeight.w400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill that, given an [onChanged] callback, opens a small menu of
/// [options] right there in the table — no need to open the mimo just to
/// flip its priority or status.
class _EditablePill extends StatelessWidget {
  const _EditablePill({
    required this.label,
    required this.color,
    required this.background,
    required this.options,
    required this.current,
    required this.onChanged,
  });

  final String label;
  final Color color;
  final Color background;
  final Map<String, String> options;
  final String current;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final pill = _Pill(label: label, color: color, background: background, compact: true);
    if (onChanged == null) return pill;

    return PopupMenuButton<String>(
      tooltip: '',
      padding: EdgeInsets.zero,
      offset: const Offset(0, 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final entry in options.entries)
          PopupMenuItem(
            value: entry.key,
            child: Row(
              children: [
                if (entry.key == current) Icon(Icons.check, size: 16, color: MimoColors.gradientA),
                if (entry.key != current) const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(entry.value),
              ],
            ),
          ),
      ],
      child: pill,
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
