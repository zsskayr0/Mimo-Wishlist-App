import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/repositories/folder_repository.dart';

class InviteMemberSheet extends StatefulWidget {
  const InviteMemberSheet({super.key, required this.folderId});

  final String folderId;

  static Future<bool?> show(BuildContext context, {required String folderId}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InviteMemberSheet(folderId: folderId),
    );
  }

  @override
  State<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<InviteMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _repository = FolderRepository();

  String _role = 'visualizador';
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _repository.inviteMember(
        folderId: widget.folderId,
        username: _usernameController.text,
        role: _role,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on UserNotFoundException {
      setState(() => _errorMessage = 'Nenhum usuário com esse @.');
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: colors.placeholder, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const Text('Convidar pra pasta', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome de usuário', prefixText: '@'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Digite um @usuário' : null,
              ),
              const SizedBox(height: 16),
              Text('Papel', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: colors.inkFaint)),
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
              FilledButton(
                onPressed: _isSaving ? null : _invite,
                style: FilledButton.styleFrom(
                  backgroundColor: MimoColors.gradientA,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Convidar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.selected, required this.onTap});

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
