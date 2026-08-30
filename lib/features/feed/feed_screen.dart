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

  /// Null only before the first load ever completes. A reload always
  /// swaps this in one atomic `setState` once the new data is in hand —
  /// never cleared to null first — so leaving Detail, pulling to
  /// refresh, etc. never flashes a loading spinner over an already-
  /// populated grid.
  List<Mimo>? _mimos;
  Object? _loadError;

  late Future<List<MimoTag>> _tagsFuture;
  late Future<List<Folder>> _foldersFuture;

  MimoFilters _filters = const MimoFilters();

  @override
  void initState() {
    super.initState();
    _load();
    _tagsFuture = _tagRepository.fetchAvailableTags();
    _foldersFuture = _folderRepository.fetchFolders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// A failed *refresh* (there's already something on screen) just keeps
  /// showing what's there and reports it via a snackbar — only a failed
  /// *first* load replaces the whole screen with an error state.
  Future<void> _load() async {
    try {
      final result = await _repository.fetchFeed();
      if (!mounted) return;
      setState(() {
        _mimos = result;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_mimos == null) {
        setState(() => _loadError = e);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não deu pra atualizar o Feed.')),
        );
      }
    }
  }

  void _openFolders() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FoldersScreen()));
  }

  Future<void> _openDetail(Mimo mimo) async {
    final deleted = await MimoDetailScreen.open(context, mimo: mimo);
    if (deleted == true && mounted) {
      setState(() => _mimos = _mimos?.where((m) => m.id != mimo.id).toList());
    }
    _load();
  }

  /// Table mode's inline priority/status pickers — updates the local
  /// list immediately (no reload round-trip) and writes it through.
  void _updateMimo(Mimo mimo, Mimo Function(Mimo) update) {
    setState(() {
      _mimos = _mimos?.map((m) => m.id == mimo.id ? update(m) : m).toList();
    });
  }

  void _onPriorityChanged(Mimo mimo, String priority) {
    _updateMimo(mimo, (m) => m.copyWith(priority: priority));
    _repository.updatePriority(mimo.id, priority);
  }

  void _onStatusChanged(Mimo mimo, String status) {
    _updateMimo(mimo, (m) => m.copyWith(purchaseStatus: status));
    _repository.updatePurchaseStatus(mimo.id, status);
  }

  Future<void> _openFilterSheet() async {
    final folders = await _foldersFuture;
    final tags = await _tagsFuture;
    final stores = <String>{
      for (final mimo in _mimos ?? const <Mimo>[])
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
    final isDesktop = MimoBreakpoints.isDesktop(MediaQuery.of(context).size.width);
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
          FutureBuilder<List<MimoTag>>(
            future: _tagsFuture,
            builder: (context, snapshot) {
              final tags = snapshot.data ?? const [];
              final chips = <Widget>[
                _FilterChip(label: 'Pastas', icon: Icons.folder_outlined, onTap: _openFolders),
                SizedBox(height: 20, width: 1, child: ColoredBox(color: colors.border)),
                _FilterChip(
                  label: _filters.hasActiveFilters ? 'Filtros (${_filters.activeCount})' : 'Filtros',
                  icon: Icons.tune,
                  selected: _filters.hasActiveFilters,
                  onTap: _openFilterSheet,
                ),
                for (final tag in tags)
                  _FilterChip(
                    label: '#${tag.name}',
                    selected: _filters.tagIds.contains(tag.id),
                    onTap: () => _toggleTagFilter(tag.id),
                  ),
              ];
              // Desktop has the width to spare: wrap to as many rows as
              // needed instead of a single row you have to scroll.
              // Mobile keeps the horizontal-scroll row (draggable — see
              // main.dart's app-wide mouse-drag ScrollBehavior).
              if (isDesktop) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(spacing: 8, runSpacing: 8, children: chips),
                );
              }
              return SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: chips.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => chips[index],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBody(colors, isDesktop)),
        ],
      ),
    );
  }

  Widget _buildBody(MimoColors colors, bool isDesktop) {
    if (_mimos == null && _loadError == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_mimos == null && _loadError != null) {
      return _MessageState(
        icon: Icons.error_outline,
        message: 'Não deu pra carregar o Feed.\n$_loadError',
        onRetry: _load,
      );
    }
    final all = _mimos!;
    if (all.isEmpty) {
      return _MessageState(
        icon: Icons.favorite_border,
        message: 'Nenhum mimo ainda.\nToque no + para salvar o primeiro.',
        onRetry: _load,
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
      onRefresh: _load,
      child: MimoCollectionView(
        mimos: mimos,
        onTap: _openDetail,
        isDesktop: isDesktop,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        onPriorityChanged: _onPriorityChanged,
        onStatusChanged: _onStatusChanged,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
