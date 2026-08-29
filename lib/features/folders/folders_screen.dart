import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/folder.dart';
import '../../data/repositories/folder_repository.dart';
import 'create_folder_sheet.dart';
import 'folder_detail_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final _repository = FolderRepository();
  late Future<List<Folder>> _foldersFuture;

  @override
  void initState() {
    super.initState();
    _foldersFuture = _repository.fetchFolders();
  }

  Future<void> _reload() async {
    final future = _repository.fetchFolders();
    setState(() => _foldersFuture = future);
    await future;
  }

  Future<void> _openCreateFolder() async {
    final created = await CreateFolderSheet.show(context);
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Pastas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openCreateFolder,
            tooltip: 'Nova pasta',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: FutureBuilder<List<Folder>>(
            future: _foldersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final folders = snapshot.data ?? const [];
              if (folders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_outlined, size: 32, color: colors.inkFaint),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma pasta ainda.\nToque em + para criar a primeira.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: folders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _FolderRow(
                    folder: folders[index],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => FolderDetailScreen(folder: folders[index])),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({required this.folder, required this.onTap});

  final Folder folder;
  final VoidCallback onTap;

  Color get _color => Color(int.parse('FF${folder.color.replaceFirst('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.folder_outlined, color: _color, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(folder.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${folder.mimoCount} ${folder.mimoCount == 1 ? 'mimo' : 'mimos'}',
                          style: TextStyle(fontSize: 12, color: colors.inkFaint, fontWeight: FontWeight.w600),
                        ),
                        if (folder.isShared) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: MimoColors.gradientA.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Compartilhada',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: MimoColors.gradientA),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.inkFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
