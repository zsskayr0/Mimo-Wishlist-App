import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/image_picker_sheet.dart';
import '../../data/models/folder.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/services/image_upload_service.dart';

const _folderPalette = [
  '#A6791F', // gold
  '#3F7A5C', // sage
  '#8B4F9E', // plum
  '#2E7DB0', // blue
  '#B6552C', // terracotta
  '#C2517B', // pink
];

/// Create AND edit ("customizar a pasta") share this sheet — passing
/// [editingFolder] switches it into edit mode: fields start pre-filled,
/// a cover-photo picker appears, and saving updates that folder instead
/// of creating a new one.
class CreateFolderSheet extends StatefulWidget {
  const CreateFolderSheet({super.key, this.editingFolder});

  final Folder? editingFolder;

  /// Returns the created/updated [Folder] (not just a success flag) so
  /// the caller can show it right away instead of waiting on a refetch.
  static Future<Folder?> show(BuildContext context, {Folder? editingFolder}) {
    return showModalBottomSheet<Folder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateFolderSheet(editingFolder: editingFolder),
    );
  }

  @override
  State<CreateFolderSheet> createState() => _CreateFolderSheetState();
}

class _CreateFolderSheetState extends State<CreateFolderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _repository = FolderRepository();

  String _selectedColor = _folderPalette.first;
  Uint8List? _coverBytes;
  String? _existingCoverUrl;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.editingFolder != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingFolder;
    if (editing != null) {
      _nameController.text = editing.name;
      _selectedColor = editing.color;
      _existingCoverUrl = editing.coverImageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final bytes = await pickImageBytes(context);
    if (bytes == null || !mounted) return;
    setState(() {
      _coverBytes = bytes;
      _existingCoverUrl = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      String? coverImageUrl = _existingCoverUrl;
      if (_coverBytes != null) {
        try {
          coverImageUrl = await ImageUploadService().upload(_coverBytes!);
        } catch (_) {
          coverImageUrl = _existingCoverUrl;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Salvo sem a capa — não deu pra enviar a imagem.',
                ),
              ),
            );
          }
        }
      }

      final name = _nameController.text.trim();
      if (_isEditing) {
        final editing = widget.editingFolder!;
        await _repository.updateFolder(
          folderId: editing.id,
          name: name,
          color: _selectedColor,
          coverImageUrl: () => coverImageUrl,
        );
        if (mounted) {
          Navigator.of(context).pop(
            editing.copyWith(
              name: name,
              color: _selectedColor,
              coverImageUrl: () => coverImageUrl,
            ),
          );
        }
      } else {
        final folder = await _repository.createFolder(
          name: name,
          color: _selectedColor,
        );
        if (mounted) Navigator.of(context).pop(folder);
      }
    } catch (_) {
      setState(
        () => _errorMessage = 'Não deu pra salvar a pasta. Tenta de novo.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _colorFromHex(String hex) =>
      Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final hasCover = _coverBytes != null || _existingCoverUrl != null;
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
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: SingleChildScrollView(
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
                    decoration: BoxDecoration(
                      color: colors.placeholder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Text(
                  _isEditing ? 'Editar pasta' : 'Nova pasta',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isEditing) ...[
                  Text(
                    'Capa',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: colors.inkFaint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickCover,
                    child: Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.placeholder,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: !hasCover
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 26,
                                  color: colors.inkFaint,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Adicionar foto de capa',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: colors.inkFaint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                _coverBytes != null
                                    ? Image.memory(
                                        _coverBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        _existingCoverUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  autofocus: !_isEditing,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Dá um nome pra pasta'
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cor',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: colors.inkFaint,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final hex in _folderPalette)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedColor = hex),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _colorFromHex(hex),
                              shape: BoxShape.circle,
                              border: _selectedColor == hex
                                  ? Border.all(color: colors.ink, width: 2.5)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 20),
                GradientButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditing ? 'Salvar alterações' : 'Criar pasta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
