import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/folder.dart';
import 'create_folder_sheet.dart';

/// Shared by the capture sheet and the "duplicate to another folder"
/// action — one place that knows how to render "pick a folder, or none".
/// Also where "criar uma pasta nova" happens on-the-go: no need to back
/// out of whatever flow opened this picker just to make a folder first.
class FolderPickerSheet extends StatefulWidget {
  const FolderPickerSheet({
    super.key,
    required this.folders,
    this.selectedFolderId,
  });

  final List<Folder> folders;
  final String? selectedFolderId;

  static Future<String?> show(
    BuildContext context, {
    required List<Folder> folders,
    String? selectedFolderId,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FolderPickerSheet(
        folders: folders,
        selectedFolderId: selectedFolderId,
      ),
    );
  }

  @override
  State<FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends State<FolderPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _colorFor(String hex) =>
      Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

  Future<void> _createFolder() async {
    final created = await CreateFolderSheet.show(context);
    // Creating one is what the user came here to do — select it and
    // close the picker right away instead of making them tap it again.
    if (created != null && mounted) Navigator.of(context).pop(created.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.folders
        : widget.folders
              .where((f) => f.name.toLowerCase().contains(query))
              .toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
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
            'Escolher pasta',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (widget.folders.length > 4) ...[
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.bg,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: colors.inkFaint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Buscar pasta',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: colors.inkFaint,
                          fontWeight: FontWeight.w300,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView(
              shrinkWrap: true,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _createFolder,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colors.inkFaint,
                              width: 1.5,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 13,
                            color: colors.inkFaint,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Criar nova pasta',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (query.isEmpty)
                  _row(
                    context,
                    id: null,
                    label: 'Nenhuma (Desorganizado)',
                    color: null,
                  ),
                for (final folder in filtered)
                  _row(
                    context,
                    id: folder.id,
                    label: folder.name,
                    color: _colorFor(folder.color),
                  ),
                if (query.isNotEmpty && filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Nenhuma pasta encontrada.',
                      style: TextStyle(color: colors.inkFaint, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String? id,
    required String label,
    required Color? color,
  }) {
    final colors = MimoColors.of(context);
    final selected = id == widget.selectedFolderId;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).pop(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color ?? colors.border,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check, size: 18, color: MimoColors.gradientA),
          ],
        ),
      ),
    );
  }
}
