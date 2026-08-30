import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/theme/mimo_colors.dart';
import '../../core/widgets/options_glyph.dart';
import '../../data/models/folder.dart';
import '../../data/models/folder_member.dart';
import '../../data/models/mimo.dart';
import '../../data/models/mimo_filters.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/mimo_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../feed/mimo_filter_sheet.dart';
import '../feed/widgets/mimo_collection_view.dart';
import '../mimo_detail/mimo_detail_screen.dart';
import 'folder_options_sheet.dart';

class FolderDetailScreen extends StatefulWidget {
  const FolderDetailScreen({super.key, required this.folder});

  final Folder folder;

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  /// See FeedScreen for why these are cached state, not a bare
  /// Future+FutureBuilder: a reload swaps them in atomically once ready,
  /// never clearing to null first, so it never flashes a loading spinner
  /// over an already-populated grid.
  List<Mimo>? _mimos;
  Object? _loadError;
  List<FolderMember> _members = const [];

  /// Mutable so FolderOptionsSheet's edits (rename/recolor/re-cover) show
  /// up in the header right away — starts from the folder the caller
  /// navigated in with, refetched after that sheet closes.
  late Folder _folder = widget.folder;

  late Future<List<MimoTag>> _tagsFuture;
  final _folderRepository = FolderRepository();
  final _searchController = TextEditingController();

  MimoFilters _filters = const MimoFilters();

  bool get _isOwner =>
      _folder.ownerId == Supabase.instance.client.auth.currentUser?.id;

  /// Owner first (synthetic — never a real folder_members row, see
  /// FolderMember), then the fetched editors/visualizadores — used both
  /// for the member-filter chip row and MimoFilterSheet's owner filter,
  /// so the folder's owner is filterable too, not just editors/viewers.
  List<FolderMember> get _roster => [
    FolderMember(
      userId: _folder.ownerId,
      username: _folder.ownerUsername ?? '—',
      displayName: _folder.ownerDisplayName,
      avatarUrl: _folder.ownerAvatarUrl,
      role: 'dono',
    ),
    ..._members,
  ];

  @override
  void initState() {
    super.initState();
    _loadMimos();
    _loadMembers();
    _tagsFuture = TagRepository().fetchAvailableTags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final members = await _folderRepository.fetchMembers(_folder.id);
    if (mounted) setState(() => _members = members);
  }

  Future<void> _openFolderOptions() async {
    final signal = await FolderOptionsSheet.show(
      context,
      folder: _folder,
      isOwner: _isOwner,
    );
    if (!mounted) return;
    if (signal == 'left') {
      Navigator.of(context).pop();
      return;
    }
    _loadMembers();
    try {
      final fresh = await _folderRepository.fetchFolder(_folder.id);
      if (mounted) setState(() => _folder = fresh);
    } catch (_) {
      // Keep showing the last-known folder — a failed refresh here
      // shouldn't be disruptive.
    }
  }

  Future<void> _loadMimos() async {
    try {
      final result = await MimoRepository().fetchByFolder(_folder.id);
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
          const SnackBar(content: Text('Não deu pra atualizar a pasta.')),
        );
      }
    }
  }

  Future<void> _openDetail(Mimo mimo) async {
    final deleted = await MimoDetailScreen.open(context, mimo: mimo);
    if (deleted == true && mounted) {
      setState(() => _mimos = _mimos?.where((m) => m.id != mimo.id).toList());
    }
    _loadMimos();
  }

  /// Table mode's inline priority/status pickers — see FeedScreen.
  void _updateMimo(Mimo mimo, Mimo Function(Mimo) update) {
    setState(() {
      _mimos = _mimos?.map((m) => m.id == mimo.id ? update(m) : m).toList();
    });
  }

  /// Table mode's blank row — see FeedScreen; here the new mimo also
  /// gets filed straight into this folder.
  Future<void> _createInline(String title) async {
    try {
      final id = await MimoRepository().createMimo(
        title: title,
        folderId: _folder.id,
      );
      final created = await MimoRepository().fetchById(id);
      if (created != null && mounted) {
        setState(() => _mimos = [...?_mimos, created]);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não deu pra criar o mimo. Tenta de novo.'),
          ),
        );
      }
    }
  }

  void _onPriorityChanged(Mimo mimo, String priority) {
    _updateMimo(mimo, (m) => m.copyWith(priority: priority));
    MimoRepository().updatePriority(mimo.id, priority);
  }

  void _onStatusChanged(Mimo mimo, String status) {
    _updateMimo(mimo, (m) => m.copyWith(purchaseStatus: status));
    MimoRepository().updatePurchaseStatus(mimo.id, status);
  }

  void _toggleOwnerFilter(String userId) {
    setState(() {
      _filters = _filters.copyWith(
        ownerId: () => _filters.ownerId == userId ? null : userId,
      );
    });
  }

  Future<void> _openFilterSheet() async {
    final tags = await _tagsFuture;
    if (!mounted) return;
    final stores = <String>{
      for (final mimo in _mimos ?? const <Mimo>[])
        if ((mimo.storeDomain ?? '').isNotEmpty) mimo.storeDomain!,
    }.toList()..sort();
    final result = await MimoFilterSheet.show(
      context,
      initial: _filters,
      folders: const [],
      tags: tags,
      stores: stores,
      members: _roster,
    );
    if (result != null) setState(() => _filters = result);
  }

  Color get _folderColor =>
      Color(int.parse('FF${_folder.color.replaceFirst('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final isDesktop = MimoBreakpoints.isDesktop(
      MediaQuery.of(context).size.width,
    );
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _folderColor,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                _folder.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: _openFolderOptions,
              child: const OptionsGlyph(),
            ),
          ),
        ],
      ),
      body: Column(
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
                      onChanged: (value) => setState(
                        () => _filters = _filters.copyWith(searchQuery: value),
                      ),
                      style: TextStyle(color: colors.ink, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar mimos ou tags',
                        hintStyle: TextStyle(
                          color: colors.inkFaint,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _openFilterSheet,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _filters.hasActiveFilters
                            ? colors.ink
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(
                        Icons.tune,
                        size: 16,
                        color: _filters.hasActiveFilters
                            ? colors.bg
                            : colors.inkFaint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_members.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _roster.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _MemberChip(
                    member: _roster[index],
                    selected: _filters.ownerId == _roster[index].userId,
                    onTap: () => _toggleOwnerFilter(_roster[index].userId),
                  ),
                ),
              ),
            ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Não deu pra carregar a pasta.',
                style: TextStyle(color: colors.inkSoft),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadMimos,
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      );
    }
    final all = _mimos!;
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
    return MimoCollectionView(
      mimos: mimos,
      onTap: _openDetail,
      isDesktop: isDesktop,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      onPriorityChanged: _onPriorityChanged,
      onStatusChanged: _onStatusChanged,
      onCreateInline: _createInline,
      ownerAvatarOf: _folder.isShared ? _ownerAvatarOf : null,
    );
  }

  /// Only for mimos that aren't the viewer's own — no point badging your
  /// own stuff ("a propriedade de quem é o mimo na pasta compartilhada").
  String? _ownerAvatarOf(Mimo mimo) {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (mimo.ownerId == myId) return null;
    for (final member in _roster) {
      if (member.userId == mimo.ownerId) return member.avatarUrl;
    }
    return null;
  }
}

/// Doubles as an owner-filter toggle — tap a member to show only their
/// mimos ("owner (para pesquisar itens de alguém em pasta compartilhada)").
class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.member, this.selected = false, this.onTap});

  final FolderMember member;
  final bool selected;
  final VoidCallback? onTap;

  String get _roleLabel {
    switch (member.role) {
      case 'dono':
        return 'dono';
      case 'editor':
        return 'editor';
      default:
        return 'visualizador';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
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
              _roleLabel,
              style: TextStyle(
                fontSize: 10.5,
                color: selected
                    ? colors.bg.withValues(alpha: 0.7)
                    : colors.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
