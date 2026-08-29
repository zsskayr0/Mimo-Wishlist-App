import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/mimo.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/mimo_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../folders/folder_picker_sheet.dart';

class MimoDetailScreen extends StatefulWidget {
  const MimoDetailScreen({super.key, required this.mimo});

  final Mimo mimo;

  @override
  State<MimoDetailScreen> createState() => _MimoDetailScreenState();
}

class _MimoDetailScreenState extends State<MimoDetailScreen> {
  final _mimoRepository = MimoRepository();
  late Mimo _mimo;
  late Future<List<MimoTag>> _tagsFuture;
  bool _isDeleted = false;

  @override
  void initState() {
    super.initState();
    _mimo = widget.mimo;
    _tagsFuture = TagRepository().fetchTagsForMimo(_mimo.id);
  }

  Future<void> _setPriority(String priority) async {
    setState(() => _mimo = _copyWith(priority: priority));
    await _mimoRepository.updatePriority(_mimo.id, priority);
  }

  Future<void> _setStatus(String status) async {
    setState(() => _mimo = _copyWith(purchaseStatus: status));
    await _mimoRepository.updatePurchaseStatus(_mimo.id, status);
  }

  Mimo _copyWith({String? priority, String? purchaseStatus}) => Mimo(
        id: _mimo.id,
        title: _mimo.title,
        priority: priority ?? _mimo.priority,
        purchaseStatus: purchaseStatus ?? _mimo.purchaseStatus,
        createdAt: _mimo.createdAt,
        folderId: _mimo.folderId,
        folderName: _mimo.folderName,
        folderColor: _mimo.folderColor,
        notes: _mimo.notes,
        coverImageUrl: _mimo.coverImageUrl,
        originalUrl: _mimo.originalUrl,
        storeDomain: _mimo.storeDomain,
        price: _mimo.price,
      );

  Future<void> _openStore() async {
    final url = _mimo.originalUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Não deu pra abrir o link.')));
    }
  }

  Future<void> _duplicate() async {
    final folders = await FolderRepository().fetchFolders();
    if (!mounted) return;
    final folderId = await FolderPickerSheet.show(context, folders: folders);
    // FolderPickerSheet.show returns null both for "no folder picked" and
    // for "user picked Nenhuma" — the sheet itself doesn't distinguish, so
    // duplicating always proceeds; picking no folder just means the copy
    // starts Desorganizado, which is a safe default either way.
    if (!mounted) return;
    await MimoRepository().duplicateToFolder(_mimo, folderId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mimo duplicado.')));
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir mimo?'),
        content: Text('"${_mimo.title}" será removido. Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _mimoRepository.deleteMimo(_mimo.id);
    _isDeleted = true;
    if (mounted) Navigator.of(context).pop(true);
  }

  String _formatPrice(double price) {
    final fixed = price.toStringAsFixed(2).replaceAll('.', ',');
    final parts = fixed.split(',');
    final intPart = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
    return 'R\$ $intPart,${parts[1]}';
  }

  Color _folderColor(MimoColors colors) {
    final hex = _mimo.folderColor;
    if (hex == null) return colors.tagGold;
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);

    return Scaffold(
        backgroundColor: colors.bg,
        body: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            _IconButton(icon: Icons.arrow_back, onTap: () => Navigator.of(context).pop(_isDeleted)),
                            const Spacer(),
                            Text(
                              'DETALHE DO MIMO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                                color: colors.inkFaint,
                              ),
                            ),
                            const Spacer(),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_horiz, color: colors.ink),
                              onSelected: (value) {
                                if (value == 'duplicate') _duplicate();
                                if (value == 'delete') _confirmDelete();
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'duplicate', child: Text('Duplicar em outra pasta')),
                                PopupMenuItem(value: 'delete', child: Text('Excluir mimo')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AspectRatio(
                          aspectRatio: 1.3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.placeholder,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: _mimo.coverImageUrl == null
                                ? Icon(Icons.image_outlined, size: 46, color: colors.inkFaint)
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(_mimo.coverImageUrl!, fit: BoxFit.cover),
                                  ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_mimo.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                if (_mimo.price != null)
                                  Text(
                                    _formatPrice(_mimo.price!),
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                if (_mimo.storeDomain != null) ...[
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: _mimo.originalUrl == null ? null : _openStore,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _mimo.storeDomain!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: MimoColors.gradientA,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        const Icon(Icons.north_east, size: 12, color: MimoColors.gradientA),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _Pill(
                                  label: _mimo.isUnorganized ? 'Desorganizado' : 'Pasta: ${_mimo.folderName ?? '—'}',
                                  color: _mimo.isUnorganized ? colors.tagGray : _folderColor(colors),
                                  background: _mimo.isUnorganized
                                      ? colors.tagGrayBg
                                      : _folderColor(colors).withValues(alpha: 0.16),
                                ),
                                FutureBuilder<List<MimoTag>>(
                                  future: _tagsFuture,
                                  builder: (context, snapshot) {
                                    final tags = snapshot.data ?? const [];
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final tag in tags)
                                          _Pill(
                                            label: '#${tag.name}',
                                            color: colors.tagPlum,
                                            background: colors.tagPlumBg,
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _Block(
                        label: 'Prioridade',
                        child: _Segmented(
                          options: const [('baixa', 'Baixa'), ('media', 'Média'), ('alta', 'Alta')],
                          value: _mimo.priority,
                          onChanged: _setPriority,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Block(
                        label: 'Status de compra',
                        child: _Segmented(
                          options: const [
                            ('desejado', 'Desejado'),
                            ('comprado', 'Comprado'),
                            ('arquivado', 'Arquivado'),
                          ],
                          value: _mimo.purchaseStatus,
                          onChanged: _setStatus,
                        ),
                      ),
                      if (_mimo.notes != null && _mimo.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _Block(
                          label: 'Notas',
                          child: Text(
                            _mimo.notes!,
                            style: TextStyle(fontSize: 14, height: 1.5, color: colors.inkSoft),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (_mimo.originalUrl != null)
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: FilledButton(
                  onPressed: _openStore,
                  style: FilledButton.styleFrom(
                    backgroundColor: MimoColors.gradientA,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Abrir na loja', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.north_east, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 18, color: colors.ink),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: colors.inkFaint),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.options, required this.value, required this.onChanged});

  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Row(
      children: [
        for (final option in options) ...[
          if (option != options.first) const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(option.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == option.$1 ? colors.ink : Colors.transparent,
                  border: Border.all(color: value == option.$1 ? colors.ink : colors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  option.$2,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: value == option.$1 ? colors.bg : colors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
