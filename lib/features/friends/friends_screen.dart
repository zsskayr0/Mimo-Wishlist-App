import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/folder.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/friendship_repository.dart';
import '../folders/folder_detail_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _repository = FriendshipRepository();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  Timer? _debounce;
  List<UserProfile> _searchResults = const [];
  bool _isSearching = false;

  /// Search results a request was just sent for — relabels/disables that
  /// row's button instead of leaving it tappable again (and looking like
  /// nothing happened).
  final Set<String> _pendingRequestIds = {};

  /// Friendship ids currently being accepted/declined — disables that
  /// row's buttons so a slow response can't be double-tapped.
  final Set<String> _respondingIds = {};

  /// Null only before the first load ever completes — see FeedScreen for
  /// why these are cached state instead of bare Future+FutureBuilder
  /// (a reload used to flash all three lists back to a loading spinner).
  List<FriendshipRequest>? _requests;
  List<UserProfile>? _friends;
  List<Folder>? _sharedFolders;

  @override
  void initState() {
    super.initState();
    _reloadLists();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _reloadLists() async {
    final results = await Future.wait([
      _repository.fetchIncomingRequests(),
      _repository.fetchFriends(),
      FolderRepository().fetchSharedWithMe(),
    ]);
    if (!mounted) return;
    setState(() {
      _requests = results[0] as List<FriendshipRequest>;
      _friends = results[1] as List<UserProfile>;
      _sharedFolders = results[2] as List<Folder>;
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = const [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await _repository.searchUsers(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _sendRequest(UserProfile profile) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _pendingRequestIds.add(profile.id));
    try {
      await _repository.sendRequest(profile.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Solicitação enviada pra @${profile.username}')),
      );
    } on FriendshipAlreadyExistsException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Vocês já têm uma solicitação ou amizade'),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _pendingRequestIds.remove(profile.id));
      messenger.showSnackBar(
        const SnackBar(content: Text('Não deu pra enviar. Tenta de novo.')),
      );
    }
  }

  /// Updates `_requests`/`_friends` locally the moment the server call
  /// succeeds — no waiting on a full 3-list reload before the request
  /// visibly moves, which was the "solicitação" flow's worst offender.
  /// Still reconciles with the server afterward, just without blocking
  /// the UI on it.
  Future<void> _respond(
    FriendshipRequest request, {
    required bool accept,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _respondingIds.add(request.friendshipId));
    try {
      await _repository.respondToRequest(request.friendshipId, accept: accept);
      if (!mounted) return;
      setState(() {
        _requests = _requests
            ?.where((r) => r.friendshipId != request.friendshipId)
            .toList();
        if (accept) _friends = [...?_friends, request.profile];
        _respondingIds.remove(request.friendshipId);
      });
      _reloadLists();
    } catch (_) {
      if (!mounted) return;
      setState(() => _respondingIds.remove(request.friendshipId));
      messenger.showSnackBar(
        const SnackBar(content: Text('Não deu pra responder. Tenta de novo.')),
      );
    }
  }

  Future<void> _openFriendActions(UserProfile friend) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _FriendActionsSheet(colors: MimoColors.of(context), friend: friend),
    );
    if (action != 'remove' || !mounted) return;
    await _repository.removeFriend(friend.id);
    _reloadLists();
  }

  void _openSharedFolder(Folder folder) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FolderDetailScreen(folder: folder)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final searching = _searchController.text.trim().isNotEmpty;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: RefreshIndicator(
            onRefresh: _reloadLists,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              children: [
                Row(
                  children: [
                    const Text(
                      'Amigos',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    _IconButton(
                      icon: Icons.search,
                      onTap: () => _searchFocusNode.requestFocus(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
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
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          decoration: const InputDecoration(
                            hintText: 'Buscar @usuário',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (searching) ...[
                  const SizedBox(height: 20),
                  _SectionLabel('Resultados'),
                  const SizedBox(height: 10),
                  if (_isSearching && _searchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_searchResults.isEmpty)
                    Text(
                      'Ninguém encontrado.',
                      style: TextStyle(color: colors.inkSoft),
                    )
                  else
                    for (final profile in _searchResults)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProfileRow(
                          profile: profile,
                          trailing: TextButton(
                            onPressed: _pendingRequestIds.contains(profile.id)
                                ? null
                                : () => _sendRequest(profile),
                            child: Text(
                              _pendingRequestIds.contains(profile.id)
                                  ? 'Pendente'
                                  : 'Adicionar',
                            ),
                          ),
                        ),
                      ),
                ] else if (_friends == null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ] else ...[
                  const SizedBox(height: 22),
                  if (_requests!.isNotEmpty) ...[
                    _SectionLabel('Solicitações'),
                    const SizedBox(height: 10),
                    for (final request in _requests!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProfileRow(
                          profile: request.profile,
                          subtitle: 'quer ser sua amiga',
                          trailing:
                              _respondingIds.contains(request.friendshipId)
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: colors.ink,
                                        foregroundColor: colors.bg,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                      ),
                                      onPressed: () =>
                                          _respond(request, accept: true),
                                      child: const Text(
                                        'Aceitar',
                                        style: TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: colors.ink,
                                        side: BorderSide(color: colors.border),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                      ),
                                      onPressed: () =>
                                          _respond(request, accept: false),
                                      child: const Text(
                                        'Recusar',
                                        style: TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                  if (_sharedFolders!.isNotEmpty) ...[
                    _SectionLabel('Pastas compartilhadas com você'),
                    const SizedBox(height: 10),
                    for (final folder in _sharedFolders!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SharedFolderRow(
                          folder: folder,
                          onTap: () => _openSharedFolder(folder),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                  _SectionLabel(
                    'Seus amigos${_friends!.isEmpty ? '' : ' · ${_friends!.length}'}',
                  ),
                  const SizedBox(height: 10),
                  if (_friends!.isEmpty)
                    Text(
                      'Nenhum amigo ainda. Busque por @usuário acima.',
                      style: TextStyle(color: colors.inkSoft),
                    )
                  else
                    for (final friend in _friends!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProfileRow(
                          profile: friend,
                          showChevron: true,
                          onTap: () => _openFriendActions(friend),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 18, color: colors.ink),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
        color: MimoColors.of(context).inkFaint,
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.profile,
    this.subtitle,
    this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  final UserProfile profile;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final row = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.placeholder,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline, size: 18, color: colors.inkFaint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.displayName ?? '@${profile.username}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle ?? '@${profile.username}',
                  style: TextStyle(fontSize: 12, color: colors.inkFaint),
                ),
              ],
            ),
          ),
          ?trailing,
          if (showChevron)
            Icon(Icons.chevron_right, color: colors.inkFaint, size: 20),
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: row,
      ),
    );
  }
}

class _SharedFolderRow extends StatelessWidget {
  const _SharedFolderRow({required this.folder, required this.onTap});

  final Folder folder;
  final VoidCallback onTap;

  Color get _color =>
      Color(int.parse('FF${folder.color.replaceFirst('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.folder_outlined, color: _color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      folder.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'de @${folder.ownerUsername ?? '—'} · ${folder.mimoCount} ${folder.mimoCount == 1 ? 'mimo' : 'mimos'}',
                      style: TextStyle(fontSize: 12, color: colors.inkFaint),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.inkFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendActionsSheet extends StatelessWidget {
  const _FriendActionsSheet({required this.colors, required this.friend});

  final MimoColors colors;
  final UserProfile friend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              '@${friend.username}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Amigos'),
          ),
          ListTile(
            leading: const Icon(
              Icons.person_remove_outlined,
              color: Colors.red,
            ),
            title: const Text(
              'Remover amizade',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => Navigator.of(context).pop('remove'),
          ),
        ],
      ),
    );
  }
}
