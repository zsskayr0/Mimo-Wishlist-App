import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/mimo_colors.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_repository.dart';

/// Shared by "Editar perfil" (Perfil tab) and the account row
/// (Configurações) — same fields either way. Returns the updated
/// [UserProfile] so the caller can refresh without a refetch.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.profile});

  final UserProfile profile;

  static Future<UserProfile?> show(BuildContext context, {required UserProfile profile}) {
    return showModalBottomSheet<UserProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(profile: profile),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  final _repository = UserRepository();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName ?? '');
    _usernameController = TextEditingController(text: widget.profile.username);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _repository.updateProfile(
        userId: widget.profile.id,
        username: _usernameController.text.trim(),
        displayName: _nameController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(
          UserProfile(
            id: widget.profile.id,
            username: _usernameController.text.trim().toLowerCase(),
            displayName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
            avatarUrl: widget.profile.avatarUrl,
          ),
        );
      }
    } on UsernameAlreadyTakenException {
      setState(() => _errorMessage = 'Esse nome de usuário já está em uso.');
    } catch (_) {
      setState(() => _errorMessage = 'Não deu pra salvar. Tenta de novo.');
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
              const Text('Editar perfil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _usernameController,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]'))],
                decoration: const InputDecoration(labelText: 'Usuário', prefixText: '@'),
                validator: (v) => (v == null || !_usernamePattern.hasMatch(v))
                    ? '3-20 letras, números ou _'
                    : null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              GradientButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
