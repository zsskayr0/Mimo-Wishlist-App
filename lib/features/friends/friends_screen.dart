import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/friendship_repository.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _repository = FriendshipRepository();
  final _searchController = TextEditingController();

  Timer? _debounce;
  List<UserProfile> _searchResults = const [];
  bool _isSearching = false;

  late Future<List<FriendshipRequest>> _requestsFuture;
  late Future<List<UserProfile>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _repository.fetchIncomingRequests();
    _friendsFuture = _repository.fetchFriends();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _reloadLists() {
    setState(() {
      _requestsFuture = _repository.fetchIncomingRequests();
      _friendsFuture = _repository.fetchFriends();
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

  @override
  Widget build(BuildContext context) {
    final searching = _searchController.text.trim().isNotEmpty;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            children: [
              const Text('Amigos', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: MimoColors.surface,
                  border: Border.all(color: MimoColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: MimoColors.inkFaint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
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
                  Text('Ninguém encontrado.', style: TextStyle(color: MimoColors.inkSoft))
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
                                      backgroundColor: MimoColors.ink,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () => _respond(request, accept: true),
                                    child: const Text('Aceitar', style: TextStyle(fontSize: 12.5)),
                                  ),
                                  const SizedBox(width: 6),
                                  TextButton(
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
                _SectionLabel('Seus amigos'),
                const SizedBox(height: 10),
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
                    if (friends.isEmpty) {
                      return Text(
                        'Nenhum amigo ainda. Busque por @usuário acima.',
                        style: TextStyle(color: MimoColors.inkSoft),
                      );
                    }
                    return Column(
                      children: [
                        for (final friend in friends)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ProfileRow(profile: friend),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: MimoColors.inkFaint),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.profile, this.subtitle, this.trailing});

  final UserProfile profile;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MimoColors.surface,
        border: Border.all(color: MimoColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: MimoColors.placeholder, shape: BoxShape.circle),
            child: const Icon(Icons.person_outline, size: 18, color: MimoColors.inkFaint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('@${profile.username}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(fontSize: 12, color: MimoColors.inkFaint)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
