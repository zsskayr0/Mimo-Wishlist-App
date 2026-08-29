import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/folder.dart';
import '../../data/repositories/folder_repository.dart';

const _folderPalette = [
  '#A6791F', // gold
  '#3F7A5C', // sage
  '#8B4F9E', // plum
  '#2E7DB0', // blue
  '#B6552C', // terracotta
  '#C2517B', // pink
];

class CreateFolderSheet extends StatefulWidget {
  const CreateFolderSheet({super.key});

  /// Returns the created [Folder] (not just a success flag) so the caller
  /// can show it right away instead of waiting on a refetch.
  static Future<Folder?> show(BuildContext context) {
    return showModalBottomSheet<Folder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateFolderSheet(),
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
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final folder = await _repository.createFolder(name: _nameController.text.trim(), color: _selectedColor);
      if (mounted) Navigator.of(context).pop(folder);
    } catch (_) {
      setState(() => _errorMessage = 'Não deu pra criar a pasta. Tenta de novo.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _colorFromHex(String hex) => Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

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
                  decoration: BoxDecoration(
                    color: colors.placeholder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const Text('Nova pasta', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Dá um nome pra pasta' : null,
              ),
              const SizedBox(height: 16),
              Text('Cor', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: colors.inkFaint)),
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
                    : const Text('Criar pasta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
