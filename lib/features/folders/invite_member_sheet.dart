import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/theme/mimo_colors.dart';
import '../../core/widgets/floating_dialog.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/friendship_repository.dart';

/// Was a plain "type an exact @username and hope it exists" field — now a
/// live search-as-you-type (same debounce/behavior as Amigos' search),
/// so inviting means picking a real person instead of guessing spelling.
class InviteMemberSheet extends StatefulWidget {
  const InviteMemberSheet({
    super.key,
    required this.folderId,
    this.existingMemberIds = const {},
    this.isDesktop = false,
  });

  final String folderId;

  /// Already-in-the-folder user ids, filtered out of search results.
  final Set<String> existingMemberIds;

  /// Set by [show] only — swaps the outer chrome (rounded-all-corners
  /// centered card, no drag handle, fixed width) without touching the
  /// form, matching every other sheet's desktop treatment.
  final bool isDesktop;

  static Future<bool?> show(
    BuildContext context, {
    required String folderId,
    Set<String> existingMemberIds = const {},
  }) {
    if (MimoBreakpoints.isDesktop(MediaQuery.of(context).size.width)) {
      return showFloatingDialog<bool>(
        context,
        builder: (_) => InviteMemberSheet(
          folderId: folderId,
          existingMemberIds: existingMemberIds,
          isDesktop: true,
        ),
      );
    }
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InviteMemberSheet(
        folderId: folderId,
        existingMemberIds: existingMemberIds,
      ),
    );
  }

  @override
  State<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<InviteMemberSheet> {
  final _searchController = TextEditingController();
  final _friendshipRepository = FriendshipRepository();
  final _folderRepository = FolderRepository();

  Timer? _debounce;
  List<UserProfile> _results = const [];
  bool _isSearching = false;
  UserProfile? _selected;

  String _role = 'visualizador';
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = const [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _friendshipRepository.searchUsers(query);
        if (!mounted) return;
        setState(() {
          _results = results
              .where((p) => !widget.existingMemberIds.contains(p.id))
              .toList();
          _isSearching = false;
        });
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _select(UserProfile profile) {
    setState(() {
      _selected = profile;
      _results = const [];
      _errorMessage = null;
      _searchController.clear();
    });
  }

  Future<void> _invite() async {
    final selected = _selected;
    if (selected == null) {
      setState(() => _errorMessage = 'Escolhe alguém na busca acima.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _folderRepository.addMember(
        folderId: widget.folderId,
        userId: selected.id,
        role: _role,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AlreadyMemberException {
      setState(() => _errorMessage = 'Essa pessoa já está na pasta.');
    } catch (_) {
      setState(() => _errorMessage = 'Não deu pra convidar. Tenta de novo.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final form = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A drag handle implies "swipe down to dismiss", which only
        // makes sense for the bottom-sheet presentation.
        if (!widget.isDesktop)
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.placeholder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        const Text(
          'Convidar pra pasta',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_selected != null)
          _SelectedChip(
            profile: _selected!,
            colors: colors,
            onClear: () => setState(() => _selected = null),
          )
        else ...[
          TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              labelText: 'Nome de usuário',
              prefixText: '@',
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isSearching && _results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_searchController.text.trim().isNotEmpty &&
                      _results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Ninguém encontrado.',
                        style: TextStyle(color: colors.inkSoft),
                      ),
                    )
                  else
                    for (final profile in _results)
                      _SearchResultRow(
                        profile: profile,
                        colors: colors,
                        onTap: () => _select(profile),
                      ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Papel',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: colors.inkFaint,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _RoleChip(
                label: 'Visualizador',
                selected: _role == 'visualizador',
                onTap: () => setState(() => _role = 'visualizador'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RoleChip(
                label: 'Editor',
                selected: _role == 'editor',
                onTap: () => setState(() => _role = 'editor'),
              ),
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 20),
        GradientButton(
          onPressed: _isSaving ? null : _invite,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Convidar'),
        ),
      ],
    );

    if (widget.isDesktop) {
      // showFloatingDialog already centers this and handles tap-outside
      // — just the sized card itself here. A real `Material` ancestor
      // (not just a decorated Container) — every InkWell/Ink inside
      // (GradientButton, the role chips, search rows...) throws "No
      // Material widget found" the moment it builds without one.
      return SizedBox(
        width: 420,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
              child: form,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: form,
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.profile,
    required this.colors,
    required this.onTap,
  });

  final UserProfile profile;
  final MimoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _Avatar(url: profile.avatarUrl, colors: colors, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '@${profile.username}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (profile.displayName != null)
                    Text(
                      profile.displayName!,
                      style: TextStyle(fontSize: 11.5, color: colors.inkFaint),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  const _SelectedChip({
    required this.profile,
    required this.colors,
    required this.onClear,
  });

  final UserProfile profile;
  final MimoColors colors;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: MimoColors.gradientA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Avatar(url: profile.avatarUrl, colors: colors, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '@${profile.username}',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onClear,
            child: Icon(Icons.close, size: 18, color: colors.inkFaint),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.colors, required this.size});

  final String? url;
  final MimoColors colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: colors.placeholder,
        child: url == null
            ? Icon(
                Icons.person_outline,
                size: size * 0.55,
                color: colors.inkFaint,
              )
            : Image.network(url!, fit: BoxFit.cover),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.ink : colors.bg,
          border: Border.all(color: selected ? colors.ink : colors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? colors.bg : colors.ink,
          ),
        ),
      ),
    );
  }
}
