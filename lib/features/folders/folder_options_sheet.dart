import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/folder.dart';
import '../../data/models/folder_member.dart';
import '../../data/repositories/folder_repository.dart';
import 'create_folder_sheet.dart';
import 'invite_member_sheet.dart';

/// Replaces the old bare "Convidar" button — this is now the folder's
/// full management surface: who has access (owner tagged "Dono", plus
/// editors/visualizadores), inviting more people, editing the folder
/// (name/color/cover), transferring ownership, and deleting it.
///
/// Returns `'left'` when the current viewer no longer belongs to this
/// folder the same way afterward (deleted, or ownership transferred away
/// from them) — FolderDetailScreen should pop itself in that case. Any
/// other result (including a plain dismiss) just means "maybe something
/// changed, reload" — FolderDetailScreen does that unconditionally since
/// it's cheap.
class FolderOptionsSheet extends StatefulWidget {
  const FolderOptionsSheet({
    super.key,
    required this.folder,
    required this.isOwner,
  });

  final Folder folder;
  final bool isOwner;

  static Future<String?> show(
    BuildContext context, {
    required Folder folder,
    required bool isOwner,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FolderOptionsSheet(folder: folder, isOwner: isOwner),
    );
  }

  @override
  State<FolderOptionsSheet> createState() => _FolderOptionsSheetState();
}

class _FolderOptionsSheetState extends State<FolderOptionsSheet> {
  final _repository = FolderRepository();

  late Folder _current = widget.folder;
  List<FolderMember>? _members;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = await _repository.fetchMembers(_current.id);
    if (mounted) setState(() => _members = members);
  }

  /// Owner first (synthetic — never a real folder_members row), then
  /// editors, then visualizadores.
  List<FolderMember> get _roster {
    final owner = FolderMember(
      userId: _current.ownerId,
      username: _current.ownerUsername ?? '—',
      displayName: _current.ownerDisplayName,
      avatarUrl: _current.ownerAvatarUrl,
      role: 'dono',
    );
    final members = [...?_members]
      ..sort((a, b) {
        if (a.role == b.role) return 0;
        return a.role == 'editor' ? -1 : 1;
      });
    return [owner, ...members];
  }

  Future<void> _invite() async {
    await InviteMemberSheet.show(
      context,
      folderId: _current.id,
      existingMemberIds: {...?_members?.map((m) => m.userId)},
    );
    _loadMembers();
  }

  Future<void> _editFolder() async {
    final updated = await CreateFolderSheet.show(
      context,
      editingFolder: _current,
    );
    if (updated != null && mounted) setState(() => _current = updated);
  }

  Future<void> _openMemberActions(FolderMember member) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemberActionsSheet(member: member),
    );
    if (action == 'transfer') {
      await _transferOwnership(member);
    } else if (action == 'remove') {
      await _removeMember(member);
    }
  }

  Future<void> _transferOwnership(FolderMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transferir a pasta?'),
        content: Text(
          '@${member.username} vira o novo dono. Você vira editor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Transferir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await _repository.transferOwnership(
        folderId: _current.id,
        newOwnerId: member.userId,
      );
      if (mounted) Navigator.of(context).pop('left');
    } catch (_) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não deu pra transferir a pasta. Tenta de novo.'),
          ),
        );
      }
    }
  }

  Future<void> _removeMember(FolderMember member) async {
    setState(() => _isBusy = true);
    try {
      await _repository.removeMember(_current.id, member.userId);
      await _loadMembers();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não deu pra remover. Tenta de novo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir pasta?'),
        content: Text(
          _current.isShared
              ? 'Os mimos ficam sem pasta (Desorganizado) e o acesso compartilhado é removido. Isso não pode ser desfeito.'
              : 'Os mimos ficam sem pasta (Desorganizado). Isso não pode ser desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await _repository.deleteFolder(_current.id);
      if (mounted) Navigator.of(context).pop('left');
    } catch (_) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não deu pra excluir a pasta. Tenta de novo.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              'Opções da pasta',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'QUEM TEM ACESSO',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: colors.inkFaint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_members == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      for (final member in _roster)
                        _MemberRow(
                          member: member,
                          colors: colors,
                          onTap: widget.isOwner && !member.isOwner
                              ? () => _openMemberActions(member)
                              : null,
                        ),
                    const SizedBox(height: 8),
                    if (widget.isOwner) ...[
                      _ActionRow(
                        icon: Icons.person_add_alt_outlined,
                        label: 'Convidar mais gente',
                        onTap: _invite,
                        colors: colors,
                      ),
                      _ActionRow(
                        icon: Icons.edit_outlined,
                        label: 'Editar pasta',
                        onTap: _editFolder,
                        colors: colors,
                      ),
                      _ActionRow(
                        icon: Icons.delete_outline,
                        label: 'Excluir pasta',
                        onTap: _isBusy ? null : _confirmDelete,
                        colors: colors,
                        destructive: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.colors, this.onTap});

  final FolderMember member;
  final MimoColors colors;
  final VoidCallback? onTap;

  String get _roleLabel {
    switch (member.role) {
      case 'dono':
        return 'Dono';
      case 'editor':
        return 'Editor';
      default:
        return 'Visualizador';
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipOval(
            child: Container(
              width: 36,
              height: 36,
              color: colors.placeholder,
              child: member.avatarUrl == null
                  ? Icon(Icons.person_outline, size: 16, color: colors.inkFaint)
                  : Image.network(member.avatarUrl!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '@${member.username}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (member.displayName != null)
                  Text(
                    member.displayName!,
                    style: TextStyle(fontSize: 11.5, color: colors.inkFaint),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: member.isOwner
                  ? MimoColors.gradientA.withValues(alpha: 0.12)
                  : colors.bg,
              borderRadius: BorderRadius.circular(999),
              border: member.isOwner ? null : Border.all(color: colors.border),
            ),
            child: Text(
              _roleLabel,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: member.isOwner ? MimoColors.gradientA : colors.inkFaint,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: colors.inkFaint),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: row,
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colors,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final MimoColors colors;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : colors.ink;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberActionsSheet extends StatelessWidget {
  const _MemberActionsSheet({required this.member});

  final FolderMember member;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
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
              '@${member.username}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(member.role == 'editor' ? 'Editor' : 'Visualizador'),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Tornar dono da pasta'),
            onTap: () => Navigator.of(context).pop('transfer'),
          ),
          ListTile(
            leading: const Icon(
              Icons.person_remove_outlined,
              color: Colors.red,
            ),
            title: const Text(
              'Remover da pasta',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => Navigator.of(context).pop('remove'),
          ),
        ],
      ),
    );
  }
}
