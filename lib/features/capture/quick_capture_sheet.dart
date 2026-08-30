import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/theme/mimo_colors.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/folder.dart';
import '../../data/models/mimo.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/mimo_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/services/image_upload_service.dart';
import '../../data/services/link_metadata_service.dart';
import '../folders/folder_picker_sheet.dart';
import 'crop_image_screen.dart';

/// Manual entry, now with an assist: pasting a link fetches its Open
/// Graph / product metadata (title, price, cover image) in the
/// background and fills in whatever fields are still empty — the user
/// can always overwrite it. Passing [editingMimo] switches the sheet into
/// edit mode: fields start pre-filled and saving updates that row instead
/// of creating a new one.
class QuickCaptureSheet extends StatefulWidget {
  const QuickCaptureSheet({super.key, this.editingMimo, this.isDesktop = false});

  final Mimo? editingMimo;

  /// True when this instance is presented as a centered floating dialog
  /// (desktop) rather than a bottom sheet (mobile) — set by [show], never
  /// by a caller directly. Swaps the outer chrome (rounded-all-corners
  /// card, no drag handle, fixed width) without touching the form itself.
  final bool isDesktop;

  /// On desktop width, "add mimo" and "revisar mimo" are the same
  /// centered floating dialog the wireframe shows for add — not a bottom
  /// sheet stretched edge to edge, which read as oversized/"zoomed" on a
  /// wide window.
  static Future<bool?> show(BuildContext context, {Mimo? editingMimo}) {
    if (MimoBreakpoints.isDesktop(MediaQuery.of(context).size.width)) {
      return showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (_) => QuickCaptureSheet(editingMimo: editingMimo, isDesktop: true),
      );
    }
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickCaptureSheet(editingMimo: editingMimo),
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

  List<Folder> _folders = const [];
  List<MimoTag> _tags = const [];

  String? _selectedFolderId;
  String _priority = 'media';
  final Set<String> _selectedTagIds = {};
  String? _linkDomain;

  Uint8List? _coverBytes;
  String? _existingCoverUrl;

  Timer? _metadataDebounce;
  bool _isFetchingMetadata = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.editingMimo != null;

  @override
  void initState() {
    super.initState();
    FolderRepository().fetchFolders().then((f) {
      if (mounted) setState(() => _folders = f);
    });
    TagRepository().fetchAvailableTags().then((t) {
      if (mounted) setState(() => _tags = t);
    });
    _linkController.addListener(_onLinkChanged);

    final editing = widget.editingMimo;
    if (editing != null) {
      _titleController.text = editing.title;
      _linkController.text = editing.originalUrl ?? '';
      if (editing.price != null) _priceController.text = editing.price!.toStringAsFixed(2).replaceAll('.', ',');
      _priority = editing.priority;
      _selectedFolderId = editing.folderId;
      _linkDomain = editing.storeDomain;
      _existingCoverUrl = editing.coverImageUrl;
      _selectedTagIds.addAll(editing.tags.map((t) => t.id));
    }
  }

  @override
  void dispose() {
    _metadataDebounce?.cancel();
    _linkController.removeListener(_onLinkChanged);
    _titleController.dispose();
    _priceController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Link metadata
  // ---------------------------------------------------------------------

  void _onLinkChanged() {
    final domain = _domainFrom(_linkController.text);
    if (domain != _linkDomain) setState(() => _linkDomain = domain);

    _metadataDebounce?.cancel();
    final url = _linkController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) return;
    _metadataDebounce = Timer(const Duration(milliseconds: 700), () => _fetchMetadata(url));
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

  Future<void> _fetchMetadata(String url) async {
    setState(() => _isFetchingMetadata = true);
    final meta = await LinkMetadataService().fetch(url);
    if (!mounted) return;

    setState(() {
      _isFetchingMetadata = false;
      if (_titleController.text.trim().isEmpty && meta.title != null) {
        _titleController.text = meta.title!;
      }
      if (_priceController.text.trim().isEmpty && meta.price != null) {
        _priceController.text = meta.price!.toStringAsFixed(2).replaceAll('.', ',');
      }
    });

    if (meta.imageUrl != null && _coverBytes == null && _existingCoverUrl == null) {
      try {
        final response = await http.get(Uri.parse(meta.imageUrl!)).timeout(const Duration(seconds: 8));
        if (mounted && response.statusCode == 200) {
          setState(() => _coverBytes = response.bodyBytes);
        }
      } catch (_) {
        // No cover fetched — the user can still pick one manually.
      }
    }
  }

  // ---------------------------------------------------------------------
  // Cover image
  // ---------------------------------------------------------------------

  Future<void> _onCoverBadgeTap() async {
    if (_coverBytes == null && _existingCoverUrl == null) {
      await _pickImage();
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CoverActionSheet(colors: MimoColors.of(context)),
    );
    if (choice == 'crop' && _coverBytes != null) {
      await _openCrop(_coverBytes!);
    } else if (choice == 'replace') {
      await _pickImage();
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImageSourceSheet(colors: MimoColors.of(context)),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    await _openCrop(bytes);
  }

  Future<void> _openCrop(Uint8List bytes) async {
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => CropImageScreen(imageBytes: bytes)),
    );
    if (cropped == null) return;
    setState(() {
      _coverBytes = cropped;
      _existingCoverUrl = null;
    });
  }

  // ---------------------------------------------------------------------
  // Tags
  // ---------------------------------------------------------------------

  Future<void> _createTag() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NewTagSheet(),
    );
    if (name == null || name.isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final tag = await TagRepository().createTag(name);
      if (!mounted) return;
      setState(() {
        _tags = [..._tags, tag];
        _selectedTagIds.add(tag.id);
      });
    } on TagAlreadyExistsException {
      messenger.showSnackBar(const SnackBar(content: Text('Você já tem uma tag com esse nome.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Não deu pra criar a tag. Tenta de novo.')));
    }
  }

  // ---------------------------------------------------------------------
  // Folder
  // ---------------------------------------------------------------------

  Future<void> _pickFolder() async {
    final folderId = await FolderPickerSheet.show(context, folders: _folders, selectedFolderId: _selectedFolderId);
    if (!mounted) return;
    setState(() => _selectedFolderId = folderId);
  }

  // ---------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // A failed upload shouldn't cost the user their title/price/tags too —
      // save without the cover and say so, rather than blocking the whole
      // mimo on one flaky request (or a bucket that isn't set up yet).
      String? coverImageUrl = _existingCoverUrl;
      if (_coverBytes != null) {
        try {
          coverImageUrl = await ImageUploadService().uploadCover(_coverBytes!);
        } catch (_) {
          coverImageUrl = _existingCoverUrl;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Salvo sem a capa — não deu pra enviar a imagem.')),
            );
          }
        }
      }

      final priceText = _priceController.text.trim().replaceAll(',', '.');
      final title = _titleController.text.trim();
      final originalUrl = _linkController.text.trim().isEmpty ? null : _linkController.text.trim();
      final price = priceText.isEmpty ? null : double.tryParse(priceText);

      if (_isEditing) {
        await _mimoRepository.updateMimo(
          mimoId: widget.editingMimo!.id,
          title: title,
          originalUrl: originalUrl,
          storeDomain: _linkDomain,
          coverImageUrl: coverImageUrl,
          price: price,
          priority: _priority,
          folderId: _selectedFolderId,
          tagIds: _selectedTagIds.toList(),
        );
      } else {
        await _mimoRepository.createMimo(
          title: title,
          originalUrl: originalUrl,
          storeDomain: _linkDomain,
          coverImageUrl: coverImageUrl,
          price: price,
          priority: _priority,
          folderId: _selectedFolderId,
          tagIds: _selectedTagIds.toList(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = 'Não deu pra salvar. Tenta de novo.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _bareField(MimoColors colors) {
    return InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.zero,
      border: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: MimoColors.gradientA)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final form = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: Form(
        key: _formKey,
        child: Column(
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
                      decoration: BoxDecoration(color: colors.placeholder, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                Row(
                  children: [
                    Text(_isEditing ? 'Editar mimo' : 'Novo mimo',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                  style: const TextStyle(fontSize: 14),
                  decoration: _bareField(colors).copyWith(
                    hintText: 'Link',
                    suffixIcon: _isFetchingMetadata
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : null,
                  ),
                ),
                if (_linkDomain != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.link, size: 13, color: colors.inkFaint),
                      const SizedBox(width: 6),
                      Text('$_linkDomain — link colado automaticamente',
                          style: TextStyle(fontSize: 12, color: colors.inkFaint)),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CoverBox(
                      bytes: _coverBytes,
                      networkUrl: _existingCoverUrl,
                      colors: colors,
                      onBadgeTap: _onCoverBadgeTap,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldCaption('TÍTULO', colors: colors),
                          TextFormField(
                            controller: _titleController,
                            textAlign: TextAlign.left,
                            decoration: _bareField(colors),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Dá um nome pro mimo' : null,
                          ),
                          const SizedBox(height: 14),
                          _FieldCaption('PREÇO', colors: colors),
                          TextFormField(
                            controller: _priceController,
                            textAlign: TextAlign.left,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _bareField(colors).copyWith(prefixText: 'R\$ '),
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
                Builder(builder: (context) {
                  final matches = _folders.where((f) => f.id == _selectedFolderId);
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
                          Icon(folder == null ? Icons.add : Icons.folder_outlined,
                              size: 16, color: folder == null ? colors.inkFaint : MimoColors.gradientA),
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
                }),
                const SizedBox(height: 18),
                _RowLabel('Tags', colors: colors),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in _tags)
                      _TagChip(
                        label: tag.name,
                        selected: _selectedTagIds.contains(tag.id),
                        colors: colors,
                        onTap: () => setState(() {
                          if (!_selectedTagIds.remove(tag.id)) _selectedTagIds.add(tag.id);
                        }),
                      ),
                    _AddTagButton(colors: colors, onTap: _createTag),
                  ],
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
                GradientButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEditing ? 'Salvar alterações' : 'Salvar no Feed'),
                ),
          ],
        ),
      ),
    );

    if (widget.isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Center(
          // An explicit width (not just a maxWidth constraint) so this
          // never depends on how the Form's children happen to resolve
          // their own intrinsic width.
          child: SizedBox(
            width: 480,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.86),
              child: Container(
                decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: form,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: form,
      ),
    );
  }
}

class _FieldCaption extends StatelessWidget {
  const _FieldCaption(this.label, {required this.colors});

  final String label;
  final MimoColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: colors.inkFaint),
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

class _CoverBox extends StatelessWidget {
  const _CoverBox({required this.bytes, required this.networkUrl, required this.colors, required this.onBadgeTap});

  final Uint8List? bytes;
  final String? networkUrl;
  final MimoColors colors;
  final VoidCallback onBadgeTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null || networkUrl != null;
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: colors.placeholder, borderRadius: BorderRadius.circular(14)),
            clipBehavior: Clip.antiAlias,
            child: bytes != null
                ? Image.memory(bytes!, fit: BoxFit.cover)
                : networkUrl != null
                    ? Image.network(networkUrl!, fit: BoxFit.cover)
                    : Icon(Icons.image_outlined, size: 26, color: colors.inkFaint),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: GestureDetector(
              onTap: onBadgeTap,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 2),
                ),
                child: Icon(hasImage ? Icons.crop : Icons.add, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet({required this.colors});

  final MimoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: colors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (Platform.isAndroid || Platform.isIOS)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Câmera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Galeria'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _CoverActionSheet extends StatelessWidget {
  const _CoverActionSheet({required this.colors});

  final MimoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: colors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.crop),
            title: const Text('Recortar a imagem'),
            onTap: () => Navigator.of(context).pop('crop'),
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Escolher outra'),
            onTap: () => Navigator.of(context).pop('replace'),
          ),
        ],
      ),
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
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: selected ? colors.bg : colors.tagPlum),
        ),
      ),
    );
  }
}

class _NewTagSheet extends StatefulWidget {
  const _NewTagSheet();

  @override
  State<_NewTagSheet> createState() => _NewTagSheetState();
}

class _NewTagSheetState extends State<_NewTagSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _create() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_nameController.text.trim());
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
              const Text('Nova tag', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nome da tag'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Dá um nome pra tag' : null,
                onFieldSubmitted: (_) => _create(),
              ),
              const SizedBox(height: 20),
              GradientButton(onPressed: _create, child: const Text('Criar')),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTagButton extends StatelessWidget {
  const _AddTagButton({required this.colors, required this.onTap});

  final MimoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.border, width: 1.5)),
        child: Icon(Icons.add, size: 14, color: colors.inkFaint),
      ),
    );
  }
}
