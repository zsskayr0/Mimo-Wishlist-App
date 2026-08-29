import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/folder.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/mimo_repository.dart';

/// Manual entry only for now — paste a link, type a title and price. The
/// share-intent and screenshot+AI paths from the wireframes are a later
/// increment; this one still respects the core rule: no folder picker here,
/// so it always lands in the Feed as "Desorganizado" until filed later.
class QuickCaptureSheet extends StatefulWidget {
  const QuickCaptureSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickCaptureSheet(),
    );
  }

  @override
  State<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<QuickCaptureSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _linkController = TextEditingController();
  final _repository = MimoRepository();
  late Future<List<Folder>> _foldersFuture;
  String? _selectedFolderId;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _foldersFuture = FolderRepository().fetchFolders();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  String? _domainFrom(String url) {
    if (url.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(url.trim());
      return uri.host.isEmpty ? null : uri.host.replaceFirst('www.', '');
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final priceText = _priceController.text.trim().replaceAll(',', '.');
      await _repository.createMimo(
        title: _titleController.text.trim(),
        originalUrl: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        storeDomain: _domainFrom(_linkController.text),
        price: priceText.isEmpty ? null : double.tryParse(priceText),
        folderId: _selectedFolderId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
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
                  decoration: BoxDecoration(
                    color: colors.placeholder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const Text('Novo mimo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Link (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Dá um nome pro mimo' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Preço (opcional)', prefixText: 'R\$ '),
              ),
              const SizedBox(height: 14),
              Text(
                'Pasta (opcional)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.inkFaint),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Folder>>(
                future: _foldersFuture,
                builder: (context, snapshot) {
                  final folders = snapshot.data ?? const [];
                  return SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FolderChip(
                          label: 'Nenhuma',
                          selected: _selectedFolderId == null,
                          onTap: () => setState(() => _selectedFolderId = null),
                        ),
                        for (final folder in folders) ...[
                          const SizedBox(width: 8),
                          _FolderChip(
                            label: folder.name,
                            selected: _selectedFolderId == folder.id,
                            onTap: () => setState(() => _selectedFolderId = folder.id),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 8),
              Text(
                'Sem pasta, o mimo aparece como "Desorganizado"',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: colors.inkFaint, fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSaving ? null : _save,
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
                    : const Text('Salvar no Feed'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  const _FolderChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.ink : colors.bg,
          border: Border.all(color: selected ? colors.ink : colors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? colors.bg : colors.ink,
          ),
        ),
      ),
    );
  }
}
