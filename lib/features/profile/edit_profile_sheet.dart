import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/mimo_colors.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/image_picker_sheet.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/image_upload_service.dart';
import '../capture/crop_image_screen.dart';

const _bioMaxLength = 50;

/// Shared by "Editar perfil" (Perfil tab) and the account row
/// (Configurações) — same fields either way: nome, @usuário, foto e uma
/// bio curta. Returns the updated [UserProfile] so the caller can
/// refresh without a refetch.
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
  late final TextEditingController _bioController;
  final _repository = UserRepository();

  Uint8List? _avatarBytes;
  bool _isSaving = false;
  bool _isPickingAvatar = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName ?? '');
    _usernameController = TextEditingController(text: widget.profile.username);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final bytes = await pickImageBytes(context);
    if (bytes == null || !mounted) return;

    setState(() => _isPickingAvatar = true);
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => CropImageScreen(imageBytes: bytes, title: 'Recortar foto', circular: true)),
    );
    if (!mounted) return;
    setState(() {
      _isPickingAvatar = false;
      if (cropped != null) _avatarBytes = cropped;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // A failed avatar upload shouldn't cost the user their name/bio
      // too — same reasoning as the mimo cover upload in QuickCaptureSheet.
      var avatarUrl = widget.profile.avatarUrl;
      if (_avatarBytes != null) {
        try {
          avatarUrl = await ImageUploadService(bucket: 'avatars').upload(_avatarBytes!);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Salvo sem a foto — não deu pra enviar a imagem.')),
            );
          }
        }
      }

      await _repository.updateProfile(
        userId: widget.profile.id,
        username: _usernameController.text.trim(),
        displayName: _nameController.text.trim(),
        avatarUrl: avatarUrl,
        bio: _bioController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(
          UserProfile(
            id: widget.profile.id,
            username: _usernameController.text.trim().toLowerCase(),
            displayName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
            avatarUrl: avatarUrl,
            bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
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
              const SizedBox(height: 18),
              Center(
                child: _AvatarPicker(
                  bytes: _avatarBytes,
                  networkUrl: widget.profile.avatarUrl,
                  colors: colors,
                  isLoading: _isPickingAvatar,
                  onTap: _pickAvatar,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
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
              const SizedBox(height: 14),
              TextFormField(
                controller: _bioController,
                maxLength: _bioMaxLength,
                maxLines: 2,
                minLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Uma frase curta sobre você',
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
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

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.bytes,
    required this.networkUrl,
    required this.colors,
    required this.isLoading,
    required this.onTap,
  });

  final Uint8List? bytes;
  final String? networkUrl;
  final MimoColors colors;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null || networkUrl != null;
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Container(
              width: 84,
              height: 84,
              color: colors.placeholder,
              alignment: Alignment.center,
              child: isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : bytes != null
                      ? Image.memory(bytes!, fit: BoxFit.cover, width: 84, height: 84)
                      : networkUrl != null
                          ? Image.network(networkUrl!, fit: BoxFit.cover, width: 84, height: 84)
                          : Icon(Icons.person_outline, size: 34, color: colors.inkFaint),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 2),
                ),
                child: Icon(hasImage ? Icons.edit : Icons.add, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
