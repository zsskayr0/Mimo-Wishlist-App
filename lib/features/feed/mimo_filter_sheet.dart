import 'package:flutter/material.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/theme/mimo_colors.dart';
import '../../core/widgets/floating_dialog.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/folder.dart';
import '../../data/models/folder_member.dart';
import '../../data/models/mimo_filters.dart';
import '../../data/models/tag.dart';

/// Filter + sort panel: tag, pasta, prioridade, status de compra and loja
/// as filters; data de inclusão and valor as sort. `owner` only shows up
/// when [members] is non-empty — it's only meaningful inside a shared
/// folder, where more than one person's mimos coexist; the personal Feed
/// has just the one owner, so there's nothing to filter there.
class MimoFilterSheet extends StatefulWidget {
  const MimoFilterSheet({
    super.key,
    required this.initial,
    required this.folders,
    required this.tags,
    required this.stores,
    this.members = const [],
    this.isDesktop = false,
  });

  final MimoFilters initial;
  final List<Folder> folders;
  final List<MimoTag> tags;
  final List<String> stores;
  final List<FolderMember> members;

  /// True when presented as a centered floating dialog (desktop) instead
  /// of a bottom sheet (mobile) — set by [show], never by a caller
  /// directly.
  final bool isDesktop;

  static Future<MimoFilters?> show(
    BuildContext context, {
    required MimoFilters initial,
    required List<Folder> folders,
    required List<MimoTag> tags,
    required List<String> stores,
    List<FolderMember> members = const [],
  }) {
    if (MimoBreakpoints.isDesktop(MediaQuery.of(context).size.width)) {
      return showFloatingDialog<MimoFilters>(
        context,
        builder: (_) => MimoFilterSheet(
          initial: initial,
          folders: folders,
          tags: tags,
          stores: stores,
          members: members,
          isDesktop: true,
        ),
      );
    }
    return showModalBottomSheet<MimoFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MimoFilterSheet(
        initial: initial,
        folders: folders,
        tags: tags,
        stores: stores,
        members: members,
      ),
    );
  }

  @override
  State<MimoFilterSheet> createState() => _MimoFilterSheetState();
}

class _MimoFilterSheetState extends State<MimoFilterSheet> {
  late MimoFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initial;
  }

  Widget _sortSection(MimoColors colors) {
    return _Section(
      label: 'Ordenar por',
      colors: colors,
      child: Row(
        children: [
          Expanded(
            child: _Choice(
              label: 'Data de inclusão',
              selected: _filters.sortBy == MimoSortBy.dateAdded,
              colors: colors,
              onTap: () => setState(() => _filters = _filters.copyWith(sortBy: MimoSortBy.dateAdded)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Choice(
              label: 'Valor',
              selected: _filters.sortBy == MimoSortBy.price,
              colors: colors,
              onTap: () => setState(() => _filters = _filters.copyWith(sortBy: MimoSortBy.price)),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(
              () => _filters = _filters.copyWith(sortDescending: !_filters.sortDescending),
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(color: colors.border, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _filters.sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                size: 16,
                color: colors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Everything below "Ordenar por" — laid out in one column on mobile,
  /// split into two on desktop (see [_twoColumns]).
  List<Widget> _filterSections(MimoColors colors) {
    return [
      if (widget.tags.isNotEmpty)
        _Section(
          label: 'Tags',
          colors: colors,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in widget.tags)
                _Choice(
                  label: '#${tag.name}',
                  selected: _filters.tagIds.contains(tag.id),
                  colors: colors,
                  pill: true,
                  onTap: () => setState(() {
                    final next = {..._filters.tagIds};
                    if (!next.remove(tag.id)) next.add(tag.id);
                    _filters = _filters.copyWith(tagIds: next);
                  }),
                ),
            ],
          ),
        ),
      if (widget.folders.isNotEmpty)
        _Section(
          label: 'Pasta',
          colors: colors,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Choice(
                label: 'Todas',
                selected: _filters.folderId == null && !_filters.unorganizedOnly,
                colors: colors,
                pill: true,
                onTap: () => setState(
                  () => _filters = _filters.copyWith(folderId: () => null, unorganizedOnly: false),
                ),
              ),
              _Choice(
                label: 'Desorganizado',
                selected: _filters.unorganizedOnly,
                colors: colors,
                pill: true,
                onTap: () => setState(
                  () => _filters = _filters.copyWith(folderId: () => null, unorganizedOnly: true),
                ),
              ),
              for (final folder in widget.folders)
                _Choice(
                  label: folder.name,
                  selected: _filters.folderId == folder.id,
                  colors: colors,
                  pill: true,
                  onTap: () => setState(
                    () => _filters = _filters.copyWith(folderId: () => folder.id, unorganizedOnly: false),
                  ),
                ),
            ],
          ),
        ),
      if (widget.members.isNotEmpty)
        _Section(
          label: 'De quem',
          colors: colors,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Choice(
                label: 'Todos',
                selected: _filters.ownerId == null,
                colors: colors,
                pill: true,
                onTap: () => setState(() => _filters = _filters.copyWith(ownerId: () => null)),
              ),
              for (final member in widget.members)
                _Choice(
                  label: '@${member.username}',
                  selected: _filters.ownerId == member.userId,
                  colors: colors,
                  pill: true,
                  onTap: () => setState(() => _filters = _filters.copyWith(ownerId: () => member.userId)),
                ),
            ],
          ),
        ),
      _Section(
        label: 'Prioridade',
        colors: colors,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Choice(
              label: 'Todas',
              selected: _filters.priority == null,
              colors: colors,
              pill: true,
              onTap: () => setState(() => _filters = _filters.copyWith(priority: () => null)),
            ),
            for (final option in const [('baixa', 'Baixa'), ('media', 'Média'), ('alta', 'Alta')])
              _Choice(
                label: option.$2,
                selected: _filters.priority == option.$1,
                colors: colors,
                pill: true,
                onTap: () => setState(() => _filters = _filters.copyWith(priority: () => option.$1)),
              ),
          ],
        ),
      ),
      _Section(
        label: 'Status de compra',
        colors: colors,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Choice(
              label: 'Todos',
              selected: _filters.purchaseStatus == null,
              colors: colors,
              pill: true,
              onTap: () => setState(() => _filters = _filters.copyWith(purchaseStatus: () => null)),
            ),
            for (final option in const [
              ('desejado', 'Desejado'),
              ('comprado', 'Comprado'),
              ('arquivado', 'Arquivado'),
            ])
              _Choice(
                label: option.$2,
                selected: _filters.purchaseStatus == option.$1,
                colors: colors,
                pill: true,
                onTap: () => setState(() => _filters = _filters.copyWith(purchaseStatus: () => option.$1)),
              ),
          ],
        ),
      ),
      if (widget.stores.isNotEmpty)
        _Section(
          label: 'Loja',
          colors: colors,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Choice(
                label: 'Todas',
                selected: _filters.storeDomain == null,
                colors: colors,
                pill: true,
                onTap: () => setState(() => _filters = _filters.copyWith(storeDomain: () => null)),
              ),
              for (final store in widget.stores)
                _Choice(
                  label: store,
                  selected: _filters.storeDomain == store,
                  colors: colors,
                  pill: true,
                  onTap: () => setState(() => _filters = _filters.copyWith(storeDomain: () => store)),
                ),
            ],
          ),
        ),
    ];
  }

  /// Round-robin, not first-half/second-half — sections vary a lot in
  /// height (Loja can run long, Prioridade never does), so alternating
  /// keeps the two columns roughly balanced instead of one running much
  /// longer than the other.
  Widget _twoColumns(List<Widget> sections) {
    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      (i.isEven ? left : right).add(sections[i]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: left)),
        const SizedBox(width: 28),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: right)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final sections = _filterSections(colors);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.isDesktop)
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: colors.placeholder, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              Row(
                children: [
                  const Text('Filtrar e ordenar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _filters = const MimoFilters()),
                    child: const Text('Limpar'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sortSection(colors),
                if (widget.isDesktop) _twoColumns(sections) else ...sections,
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: GradientButton(
            onPressed: () => Navigator.of(context).pop(_filters),
            child: const Text('Aplicar filtros'),
          ),
        ),
      ],
    );

    if (widget.isDesktop) {
      // showFloatingDialog already centers this and handles tap-outside.
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.86),
        child: Container(
          width: 680,
          decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: content,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.colors, required this.child});

  final String label;
  final MimoColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: colors.inkFaint),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
    this.pill = false,
  });

  final String label;
  final bool selected;
  final MimoColors colors;
  final VoidCallback onTap;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(pill ? 999 : 10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.ink : Colors.transparent,
          border: Border.all(color: selected ? colors.ink : colors.border, width: 1.5),
          borderRadius: BorderRadius.circular(pill ? 999 : 10),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: selected ? colors.bg : colors.ink),
        ),
      ),
    );
  }
}
