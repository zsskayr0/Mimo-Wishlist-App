import 'package:flutter/material.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/theme/mimo_colors.dart';
import '../../data/models/mimo.dart';
import '../../data/models/mimo_filters.dart';
import '../../data/models/folder.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/mimo_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../folders/folders_screen.dart';
import '../mimo_detail/mimo_detail_screen.dart';
import 'mimo_filter_sheet.dart';
import 'widgets/mimo_collection_view.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _repository = MimoRepository();
  final _tagRepository = TagRepository();
  final _folderRepository = FolderRepository();
  final _searchController = TextEditingController();

  late Future<List<Mimo>> _feedFuture;
  late Future<List<MimoTag>> _tagsFuture;
  late Future<List<Folder>> _foldersFuture;

  MimoFilters _filters = const MimoFilters();

  /// Ids removed optimistically (a confirmed delete) that the current
  /// [_feedFuture] snapshot might still list, because it was fetched
  /// before the delete happened. Filtered out at render time so removal
  /// is instant instead of waiting on the next network round-trip; cleared
  /// whenever a fresh fetch lands, since that fetch is already correct.
  final Set<String> _hiddenIds = {};

  @override
  void initState() {
    super.initState();
    _feedFuture = _repository.fetchFeed();
    _tagsFuture = _tagRepository.fetchAvailableTags();
    _foldersFuture = _folderRepository.fetchFolders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final future = _repository.fetchFeed();
    // A block body, not `() => _feedFuture = future` — an assignment
    // expression evaluates to the assigned value, so an arrow body here
    // would make the closure return a Future and setState() throws at
    // runtime ("callback argument returned a Future").
    setState(() {
      _feedFuture = future;
    });
    await future;
    if (mounted) setState(_hiddenIds.clear);
  }

  void _openFolders() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FoldersScreen()));
  }

  Future<void> _openDetail(Mimo mimo) async {
    final deleted = await MimoDetailScreen.open(context, mimo: mimo);
    if (deleted == true) setState(() => _hiddenIds.add(mimo.id));
    _reload();
  }

  Future<void> _openFilterSheet() async {
    final folders = await _foldersFuture;
    final tags = await _tagsFuture;
    final mimos = await _feedFuture;
    final stores = <String>{
      for (final mimo in mimos)
        if ((mimo.storeDomain ?? '').isNotEmpty) mimo.storeDomain!,
    }.toList()
      ..sort();
    if (!mounted) return;
    final result = await MimoFilterSheet.show(
      context,
      initial: _filters,
      folders: folders,
      tags: tags,
      stores: stores,
    );
    if (result != null) setState(() => _filters = result);
  }

  void _toggleTagFilter(String tagId) {
    setState(() {
      final next = {..._filters.tagIds};
      if (!next.remove(tagId)) next.add(tagId);
      _filters = _filters.copyWith(tagIds: next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: MimoColors.gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Text('Mimo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.ink)),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: colors.inkFaint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _filters = _filters.copyWith(searchQuery: value)),
                      style: TextStyle(color: colors.ink, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar mimos ou tags',
                        hintStyle: TextStyle(color: colors.inkFaint, fontSize: 14, fontWeight: FontWeight.w300),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    InkWell(
                      onTap: () => setState(() {
                        _searchController.clear();
                        _filters = _filters.copyWith(searchQuery: '');
                      }),
                      borderRadius: BorderRadius.circular(999),
                      child: Icon(Icons.close, size: 16, color: colors.inkFaint),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: FutureBuilder<List<MimoTag>>(
              future: _tagsFuture,
              builder: (context, snapshot) {
                final tags = snapshot.data ?? const [];
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _FilterChip(label: 'Pastas', icon: Icons.folder_outlined, onTap: _openFolders),
                    const SizedBox(width: 10),
                    Container(width: 1, color: colors.border),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: _filters.hasActiveFilters ? 'Filtros (${_filters.activeCount})' : 'Filtros',
                      icon: Icons.tune,
                      selected: _filters.hasActiveFilters,
                      onTap: _openFilterSheet,
                    ),
                    for (final tag in tags) ...[
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '#${tag.name}',
                        selected: _filters.tagIds.contains(tag.id),
                        onTap: () => _toggleTagFilter(tag.id),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Mimo>>(
              future: _feedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _MessageState(
                    icon: Icons.error_outline,
                    message: 'Não deu pra carregar o Feed.\n${snapshot.error}',
                    onRetry: _reload,
                  );
                }
                final all = (snapshot.data ?? const [])
                    .where((m) => !_hiddenIds.contains(m.id))
                    .toList();
                if (all.isEmpty) {
                  return _MessageState(
                    icon: Icons.favorite_border,
                    message: 'Nenhum mimo ainda.\nToque no + para salvar o primeiro.',
                    onRetry: _reload,
                  );
                }
                final mimos = _filters.apply(all);
                if (mimos.isEmpty) {
                  return _MessageState(
                    icon: Icons.search_off,
                    message: 'Nenhum mimo encontrado para esses filtros.',
                    retryLabel: 'Limpar filtros',
                    onRetry: () async => setState(() {
                      _searchController.clear();
                      _filters = const MimoFilters();
                    }),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: MimoCollectionView(
                        mimos: mimos,
                        onTap: _openDetail,
                        isDesktop: MimoBreakpoints.isDesktop(MediaQuery.of(context).size.width),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false, this.icon, this.onTap});

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final iconColor = selected ? colors.bg : colors.ink;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? colors.ink : colors.surface,
        border: Border.all(color: selected ? colors.ink : colors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? colors.bg : colors.ink,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return InkWell(borderRadius: BorderRadius.circular(999), onTap: onTap, child: chip);
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Tentar de novo',
  });

  final IconData icon;
  final String message;
  final Future<void> Function() onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: colors.inkFaint),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: colors.inkSoft)),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
