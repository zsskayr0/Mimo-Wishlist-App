import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/folder.dart';
import '../../data/models/mimo.dart';
import '../../data/repositories/mimo_repository.dart';
import '../feed/widgets/mimo_card.dart';

class FolderDetailScreen extends StatefulWidget {
  const FolderDetailScreen({super.key, required this.folder});

  final Folder folder;

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  late Future<List<Mimo>> _mimosFuture;

  @override
  void initState() {
    super.initState();
    _mimosFuture = MimoRepository().fetchByFolder(widget.folder.id);
  }

  Color get _folderColor =>
      Color(int.parse('FF${widget.folder.color.replaceFirst('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimoColors.bg,
      appBar: AppBar(
        backgroundColor: MimoColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: _folderColor, shape: BoxShape.circle),
            ),
            Text(widget.folder.name),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: FutureBuilder<List<Mimo>>(
            future: _mimosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final mimos = snapshot.data ?? const [];
              if (mimos.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhum mimo nesta pasta ainda.',
                    style: TextStyle(color: MimoColors.inkSoft),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 190,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemCount: mimos.length,
                itemBuilder: (context, index) => MimoCard(mimo: mimos[index]),
              );
            },
          ),
        ),
      ),
    );
  }
}
