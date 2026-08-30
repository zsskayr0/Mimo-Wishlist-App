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

  /// Null only before the first load ever completes — see FeedScreen for
  /// why this is cached state instead of a bare Future+FutureBuilder.
  List<Folder>? _folders;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _repository.fetchFolders();
      if (!mounted) return;
      setState(() {
        _folders = result;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_folders == null) {
        setState(() => _loadError = e);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não deu pra atualizar as pastas.')),
        );
      }
    }
  }

  Future<void> _openCreateFolder() async {
    final created = await CreateFolderSheet.show(context);
    if (created != null) {
      setState(() => _folders = [created, ...?_folders]);
    }
    _load();
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
          child: _buildBody(colors),
        ),
      ),
    );
  }

  Widget _buildBody(MimoColors colors) {
    if (_folders == null && _loadError == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_folders == null && _loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Não deu pra carregar as pastas.',
                style: TextStyle(color: colors.inkSoft),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Tentar de novo')),
            ],
          ),
        ),
      );
    }

    final folders = _folders!;
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
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: folders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _FolderRow(
          folder: folders[index],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FolderDetailScreen(folder: folders[index]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small overlapping avatar stack for a shared folder's members, next to
/// the "Compartilhada" badge — matches the wireframe's `.avatars` row.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.urls, required this.colors});

  final List<String?> urls;
  final MimoColors colors;

  static const _max = 3;
  static const _size = 18.0;
  static const _overlap = 6.0;

  @override
  Widget build(BuildContext context) {
    final shown = urls.take(_max).toList();
    return SizedBox(
      width: _size + (shown.length - 1) * (_size - _overlap),
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (_size - _overlap),
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.placeholder,
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: shown[i] == null
                    ? null
                    : Image.network(shown[i]!, fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({required this.folder, required this.onTap});

  final Folder folder;
  final VoidCallback onTap;

  Color get _color =>
      Color(int.parse('FF${folder.color.replaceFirst('#', '')}', radix: 16));

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
                    Text(
                      folder.name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${folder.mimoCount} ${folder.mimoCount == 1 ? 'mimo' : 'mimos'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.inkFaint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (folder.isShared) ...[
                          const SizedBox(width: 8),
                          if (folder.memberAvatarUrls.isNotEmpty) ...[
                            _AvatarStack(
                              urls: folder.memberAvatarUrls,
                              colors: colors,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: MimoColors.gradientA.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Compartilhada',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: MimoColors.gradientA,
                              ),
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
