import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/folder.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/mimo_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../folders/folder_picker_sheet.dart';

/// Manual entry only for now — paste a link, type a title and price. The
/// share-intent and screenshot+AI paths from the wireframes are a later
/// increment; this one still respects the core rule: no folder picked
/// means it lands in the Feed as "Desorganizado".
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
  final _mimoRepository = MimoRepository();

  late Future<List<Folder>> _foldersFuture;
  late Future<List<MimoTag>> _tagsFuture;
  List<Folder> _folders = const [];

  String? _selectedFolderId;
  String _priority = 'media';
  final Set<String> _selectedTagIds = {};
  String? _linkDomain;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _foldersFuture = FolderRepository().fetchFolders()..then((f) => _folders = f);
    _tagsFuture = TagRepository().fetchAvailableTags();
    _linkController.addListener(_onLinkChanged);
  }

  @override
  void dispose() {
    _linkController.removeListener(_onLinkChanged);
    _titleController.dispose();
    _priceController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _onLinkChanged() {
    final domain = _domainFrom(_linkController.text);
    if (domain != _linkDomain) setState(() => _linkDomain = domain);
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

  Future<void> _pickFolder() async {
    final folderId = await FolderPickerSheet.show(
      context,
      folders: _folders,
      selectedFolderId: _selectedFolderId,
    );
    if (!mounted) return;
    setState(() => _selectedFolderId = folderId);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final priceText = _priceController.text.trim().replaceAll(',', '.');
      await _mimoRepository.createMimo(
        title: _titleController.text.trim(),
        originalUrl: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        storeDomain: _linkDomain,
        price: priceText.isEmpty ? null : double.tryParse(priceText),
        priority: _priority,
        folderId: _selectedFolderId,
        tagIds: _selectedTagIds.toList(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = 'Não deu pra salvar. Tenta de novo.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _underlineField(MimoColors colors, String label) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      labelStyle: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: colors.inkFaint,
      ),
      border: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: MimoColors.gradientA)),
    );
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: SingleChildScrollView(
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
                Row(
                  children: [
                    const Text('Novo mimo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(9)),
                        child: Icon(Icons.close, size: 16, color: colors.inkSoft),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _linkController,
                  keyboardType: TextInputType.url,
                  decoration: _underlineField(colors, 'Link'),
                ),
                if (_linkDomain != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.link, size: 13, color: colors.inkFaint),
                      const SizedBox(width: 6),
                      Text(
                        '$_linkDomain — link colado automaticamente',
                        style: TextStyle(fontSize: 12, color: colors.inkFaint),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: colors.placeholder, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Icon(Icons.image_outlined, size: 22, color: colors.inkFaint),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: _underlineField(colors, 'Título'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Dá um nome pro mimo' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _underlineField(colors, 'Preço').copyWith(prefixText: 'R\$ '),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _RowLabel('Prioridade', colors: colors),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final option in const [('baixa', 'Baixa'), ('media', 'Média'), ('alta', 'Alta')]) ...[
                      if (option.$1 != 'baixa') const SizedBox(width: 8),
                      Expanded(
                        child: _SegmentOption(
                          label: option.$2,
                          selected: _priority == option.$1,
                          colors: colors,
                          onTap: () => setState(() => _priority = option.$1),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                _RowLabel('Pasta', colors: colors),
                const SizedBox(height: 8),
                FutureBuilder<List<Folder>>(
                  future: _foldersFuture,
                  builder: (context, snapshot) {
                    final matches = (snapshot.data ?? const <Folder>[])
                        .where((f) => f.id == _selectedFolderId);
                    final folder = matches.isEmpty ? null : matches.first;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickFolder,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: folder == null ? colors.border : MimoColors.gradientA,
                            width: folder == null ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              folder == null ? Icons.add : Icons.folder_outlined,
                              size: 16,
                              color: folder == null ? colors.inkFaint : MimoColors.gradientA,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              folder?.name ?? 'Adicionar a uma pasta (opcional)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: folder == null ? colors.inkFaint : colors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _RowLabel('Tags', colors: colors),
                const SizedBox(height: 8),
                FutureBuilder<List<MimoTag>>(
                  future: _tagsFuture,
                  builder: (context, snapshot) {
                    final tags = snapshot.data ?? const [];
                    if (tags.isEmpty) return const SizedBox.shrink();
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in tags)
                          _TagChip(
                            label: tag.name,
                            selected: _selectedTagIds.contains(tag.id),
                            colors: colors,
                            onTap: () => setState(() {
                              if (!_selectedTagIds.remove(tag.id)) _selectedTagIds.add(tag.id);
                            }),
                          ),
                      ],
                    );
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Salvar no Feed', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel(this.label, {required this.colors});

  final String label;
  final MimoColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: colors.inkFaint),
    );
  }
}

class _SegmentOption extends StatelessWidget {
  const _SegmentOption({required this.label, required this.selected, required this.colors, required this.onTap});

  final String label;
  final bool selected;
  final MimoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.ink : Colors.transparent,
          border: Border.all(color: selected ? colors.ink : colors.border, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? colors.bg : colors.ink),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.selected, required this.colors, required this.onTap});

  final String label;
  final bool selected;
  final MimoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.tagPlum : colors.tagPlumBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '#$label',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: selected ? colors.bg : colors.tagPlum,
          ),
        ),
      ),
    );
  }
}
