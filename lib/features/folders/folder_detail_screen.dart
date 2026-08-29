import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/folder.dart';
import '../../data/models/folder_member.dart';
import '../../data/models/mimo.dart';
import '../../data/models/mimo_filters.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/mimo_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../feed/mimo_filter_sheet.dart';
import '../feed/widgets/mimo_card.dart';
import '../mimo_detail/mimo_detail_screen.dart';
import 'invite_member_sheet.dart';

class FolderDetailScreen extends StatefulWidget {
  const FolderDetailScreen({super.key, required this.folder});

  final Folder folder;

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  late Future<List<Mimo>> _mimosFuture;
  late Future<List<FolderMember>> _membersFuture;
  late Future<List<MimoTag>> _tagsFuture;
  final _searchController = TextEditingController();

  MimoFilters _filters = const MimoFilters();

  /// See FeedScreen for why this exists: makes a delete disappear
  /// instantly instead of waiting on the next fetch to land.
  final Set<String> _hiddenIds = {};

  bool get _isOwner => widget.folder.ownerId == Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _mimosFuture = MimoRepository().fetchByFolder(widget.folder.id);
    _membersFuture = FolderRepository().fetchMembers(widget.folder.id);
    _tagsFuture = TagRepository().fetchAvailableTags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadMembers() {
    // Block body — an arrow body assigning a Future-typed field makes the
    // closure itself return that Future, which setState() rejects at
    // runtime ("callback argument returned a Future").
    setState(() {
      _membersFuture = FolderRepository().fetchMembers(widget.folder.id);
    });
  }

  Future<void> _openInvite() async {
    final invited = await InviteMemberSheet.show(context, folderId: widget.folder.id);
    if (invited == true) _reloadMembers();
  }

  Future<void> _reloadMimos() async {
    final future = MimoRepository().fetchByFolder(widget.folder.id);
    setState(() {
      _mimosFuture = future;
    });
    await future;
    if (mounted) setState(_hiddenIds.clear);
  }

  Future<void> _openDetail(Mimo mimo) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MimoDetailScreen(mimo: mimo)),
    );
    if (deleted == true) setState(() => _hiddenIds.add(mimo.id));
    _reloadMimos();
  }

  void _toggleOwnerFilter(String userId) {
    setState(() {
      _filters = _filters.copyWith(ownerId: () => _filters.ownerId == userId ? null : userId);
    });
  }

  Future<void> _openFilterSheet() async {
    final tags = await _tagsFuture;
    final members = await _membersFuture;
    final mimos = await _mimosFuture;
    final stores = <String>{
      for (final mimo in mimos)
        if ((mimo.storeDomain ?? '').isNotEmpty) mimo.storeDomain!,
    }.toList()
      ..sort();
    if (!mounted) return;
    final result = await MimoFilterSheet.show(
      context,
      initial: _filters,
      folders: const [],
      tags: tags,
      stores: stores,
      members: members,
    );
    if (result != null) setState(() => _filters = result);
  }

  Color get _folderColor =>
      Color(int.parse('FF${widget.folder.color.replaceFirst('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: _folderColor, shape: BoxShape.circle),
            ),
            Text(widget.folder.name),
          ],
        ),
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.person_add_alt_outlined),
              tooltip: 'Convidar',
              onPressed: _openInvite,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                          onChanged: (value) =>
                              setState(() => _filters = _filters.copyWith(searchQuery: value)),
                          style: TextStyle(color: colors.ink, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Buscar mimos ou tags',
                            hintStyle:
                                TextStyle(color: colors.inkFaint, fontSize: 14, fontWeight: FontWeight.w300),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _openFilterSheet,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _filters.hasActiveFilters ? colors.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            Icons.tune,
                            size: 16,
                            color: _filters.hasActiveFilters ? colors.bg : colors.inkFaint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FutureBuilder<List<FolderMember>>(
                future: _membersFuture,
                builder: (context, snapshot) {
                  final members = snapshot.data ?? const [];
                  if (members.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: SizedBox(
                      height: 30,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final member in members) ...[
                            _MemberChip(
                              member: member,
                              selected: _filters.ownerId == member.userId,
                              onTap: () => _toggleOwnerFilter(member.userId),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              Expanded(
                child: FutureBuilder<List<Mimo>>(
                  future: _mimosFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final all = (snapshot.data ?? const [])
                        .where((m) => !_hiddenIds.contains(m.id))
                        .toList();
                    if (all.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhum mimo nesta pasta ainda.',
                          style: TextStyle(color: colors.inkSoft),
                        ),
                      );
                    }
                    final mimos = _filters.apply(all);
                    if (mimos.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhum mimo encontrado para esses filtros.',
                          style: TextStyle(color: colors.inkSoft),
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 190,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.52,
                      ),
                      itemCount: mimos.length,
                      itemBuilder: (context, index) => MimoCard(
                        mimo: mimos[index],
                        onTap: () => _openDetail(mimos[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Doubles as an owner-filter toggle — tap a member to show only their
/// mimos ("owner (para pesquisar itens de alguém em pasta compartilhada)").
class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.member, this.selected = false, this.onTap});

  final FolderMember member;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final isEditor = member.role == 'editor';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.ink : colors.surface,
          border: Border.all(color: selected ? colors.ink : colors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '@${member.username}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? colors.bg : colors.ink,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              isEditor ? 'editor' : 'visualizador',
              style: TextStyle(fontSize: 10.5, color: selected ? colors.bg.withValues(alpha: 0.7) : colors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}
