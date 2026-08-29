import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/folder.dart';

/// Shared by the capture sheet and the "duplicate to another folder"
/// action — one place that knows how to render "pick a folder, or none".
class FolderPickerSheet extends StatelessWidget {
  const FolderPickerSheet({super.key, required this.folders, this.selectedFolderId});

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
      builder: (_) => FolderPickerSheet(folders: folders, selectedFolderId: selectedFolderId),
    );
  }

  Color _colorFor(String hex) => Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
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
              decoration: BoxDecoration(color: colors.placeholder, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const Text('Escolher pasta', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView(
              shrinkWrap: true,
              children: [
                _row(context, id: null, label: 'Nenhuma (Desorganizado)', color: null),
                for (final folder in folders)
                  _row(context, id: folder.id, label: folder.name, color: _colorFor(folder.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, {required String? id, required String label, required Color? color}) {
    final colors = MimoColors.of(context);
    final selected = id == selectedFolderId;
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
              decoration: BoxDecoration(color: color ?? colors.border, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            if (selected) Icon(Icons.check, size: 18, color: MimoColors.gradientA),
          ],
        ),
      ),
    );
  }
}
