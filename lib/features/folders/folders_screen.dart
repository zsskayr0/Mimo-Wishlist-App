import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/theme/mimo_colors.dart';
import '../../data/models/folder.dart';
import '../../data/repositories/folder_repository.dart';
import 'create_folder_sheet.dart';
import 'folder_detail_screen.dart';
import 'folder_options_sheet.dart';
import 'widgets/folder_tiles.dart';

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

  Future<void> _openFolderOptions(Folder folder) async {
    final isOwner =
        folder.ownerId == Supabase.instance.client.auth.currentUser?.id;
    await FolderOptionsSheet.show(context, folder: folder, isOwner: isOwner);
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
    final isDesktop = MimoBreakpoints.isDesktop(
      MediaQuery.of(context).size.width,
    );
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: folders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => FolderListTile(
          folder: folders[index],
          count: folders[index].mimoCount,
          isDesktop: isDesktop,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FolderDetailScreen(folder: folders[index]),
            ),
          ),
          onOptions: () => _openFolderOptions(folders[index]),
        ),
      ),
    );
  }
}
