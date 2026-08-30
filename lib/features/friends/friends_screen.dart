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

  late Future<List<FriendshipRequest>> _requestsFuture;
  late Future<List<UserProfile>> _friendsFuture;
  late Future<List<Folder>> _sharedFoldersFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _repository.fetchIncomingRequests();
    _friendsFuture = _repository.fetchFriends();
    _sharedFoldersFuture = FolderRepository().fetchSharedWithMe();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _reloadLists() {
    setState(() {
      _requestsFuture = _repository.fetchIncomingRequests();
      _friendsFuture = _repository.fetchFriends();
      _sharedFoldersFuture = FolderRepository().fetchSharedWithMe();
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
      final results = await _repository.searchUsers(query);
      if (mounted) setState(() => _searchResults = results);
    });
  }

  Future<void> _sendRequest(UserProfile profile) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repository.sendRequest(profile.id);
      messenger.showSnackBar(SnackBar(content: Text('Solicitação enviada pra @${profile.username}')));
    } on FriendshipAlreadyExistsException {
      messenger.showSnackBar(const SnackBar(content: Text('Vocês já têm uma solicitação ou amizade')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Não deu pra enviar. Tenta de novo.')));
    }
  }

  Future<void> _respond(FriendshipRequest request, {required bool accept}) async {
    await _repository.respondToRequest(request.friendshipId, accept: accept);
    _reloadLists();
  }

  Future<void> _openFriendActions(UserProfile friend) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FriendActionsSheet(colors: MimoColors.of(context), friend: friend),
    );
    if (action != 'remove' || !mounted) return;
    await _repository.removeFriend(friend.id);
    _reloadLists();
  }

  void _openSharedFolder(Folder folder) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => FolderDetailScreen(folder: folder)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final searching = _searchController.text.trim().isNotEmpty;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            children: [
              Row(
                children: [
                  const Text('Amigos', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _IconButton(icon: Icons.search, onTap: () => _searchFocusNode.requestFocus()),
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
                  Text('Ninguém encontrado.', style: TextStyle(color: colors.inkSoft))
                else
                  for (final profile in _searchResults)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ProfileRow(
                        profile: profile,
                        trailing: TextButton(
                          onPressed: () => _sendRequest(profile),
                          child: const Text('Adicionar'),
                        ),
                      ),
                    ),
              ] else ...[
                const SizedBox(height: 22),
                FutureBuilder<List<FriendshipRequest>>(
                  future: _requestsFuture,
                  builder: (context, snapshot) {
                    final requests = snapshot.data ?? const [];
                    if (requests.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Solicitações'),
                        const SizedBox(height: 10),
                        for (final request in requests)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ProfileRow(
                              profile: request.profile,
                              subtitle: 'quer ser sua amiga',
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colors.ink,
                                      foregroundColor: colors.bg,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () => _respond(request, accept: true),
                                    child: const Text('Aceitar', style: TextStyle(fontSize: 12.5)),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.ink,
                                      side: BorderSide(color: colors.border),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () => _respond(request, accept: false),
                                    child: const Text('Recusar', style: TextStyle(fontSize: 12.5)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
                FutureBuilder<List<Folder>>(
                  future: _sharedFoldersFuture,
                  builder: (context, snapshot) {
                    final folders = snapshot.data ?? const [];
                    if (folders.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Pastas compartilhadas com você'),
                        const SizedBox(height: 10),
                        for (final folder in folders)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SharedFolderRow(folder: folder, onTap: () => _openSharedFolder(folder)),
                          ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
                FutureBuilder<List<UserProfile>>(
                  future: _friendsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final friends = snapshot.data ?? const [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Seus amigos${friends.isEmpty ? '' : ' · ${friends.length}'}'),
                        const SizedBox(height: 10),
                        if (friends.isEmpty)
                          Text(
                            'Nenhum amigo ainda. Busque por @usuário acima.',
                            style: TextStyle(color: colors.inkSoft),
                          )
                        else
                          for (final friend in friends)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ProfileRow(
                                profile: friend,
                                showChevron: true,
                                onTap: () => _openFriendActions(friend),
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ],
            ],
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
            decoration: BoxDecoration(color: colors.placeholder, shape: BoxShape.circle),
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle ?? '@${profile.username}',
                  style: TextStyle(fontSize: 12, color: colors.inkFaint),
                ),
              ],
            ),
          ),
          ?trailing,
          if (showChevron) Icon(Icons.chevron_right, color: colors.inkFaint, size: 20),
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: row),
    );
  }
}

class _SharedFolderRow extends StatelessWidget {
  const _SharedFolderRow({required this.folder, required this.onTap});

  final Folder folder;
  final VoidCallback onTap;

  Color get _color => Color(int.parse('FF${folder.color.replaceFirst('#', '')}', radix: 16));

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
                decoration: BoxDecoration(color: _color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(11)),
                child: Icon(Icons.folder_outlined, color: _color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(folder.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: colors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('@${friend.username}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Amigos'),
          ),
          ListTile(
            leading: const Icon(Icons.person_remove_outlined, color: Colors.red),
            title: const Text('Remover amizade', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.of(context).pop('remove'),
          ),
        ],
      ),
    );
  }
}
