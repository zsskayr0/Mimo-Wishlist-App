import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/mimo.dart';
import '../../data/repositories/mimo_repository.dart';
import '../folders/folders_screen.dart';
import '../mimo_detail/mimo_detail_screen.dart';
import 'widgets/mimo_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _repository = MimoRepository();
  late Future<List<Mimo>> _feedFuture;

  /// Ids removed optimistically (a confirmed delete) that the current
  /// [_feedFuture] snapshot might still list, because it was fetched
  /// before the delete happened. Filtered out at render time so removal
  /// is instant instead of waiting on the next network round-trip; cleared
  /// whenever a fresh fetch lands, since that fetch is already correct.
  final Set<String> _hiddenIds = {};

  @override
  void initState() {
    super.initState();
    _feedFuture = _repository.fetchFeed();
  }

  Future<void> _reload() async {
    final future = _repository.fetchFeed();
    setState(() => _feedFuture = future);
    await future;
    if (mounted) setState(_hiddenIds.clear);
  }

  void _openFolders() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FoldersScreen()));
  }

  Future<void> _openDetail(Mimo mimo) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MimoDetailScreen(mimo: mimo)),
    );
    if (deleted == true) setState(() => _hiddenIds.add(mimo.id));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: MimoColors.gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Text('Mimo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.ink)),
                const Spacer(),
                _IconButton(icon: Icons.search, onTap: () {}),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: colors.inkFaint),
                  const SizedBox(width: 10),
                  Text(
                    'Buscar mimos ou @usuário',
                    style: TextStyle(color: colors.inkFaint, fontSize: 14, fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(label: 'Pastas', icon: Icons.folder_outlined, onTap: _openFolders),
                const SizedBox(width: 10),
                Container(width: 1, color: colors.border),
                const SizedBox(width: 10),
                const _FilterChip(label: 'Todos', selected: true),
                const SizedBox(width: 8),
                const _FilterChip(label: 'Casa'),
                const SizedBox(width: 8),
                const _FilterChip(label: 'Tech'),
                const SizedBox(width: 8),
                const _FilterChip(label: 'Roupas'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Mimo>>(
              future: _feedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _MessageState(
                    icon: Icons.error_outline,
                    message: 'Não deu pra carregar o Feed.\n${snapshot.error}',
                    onRetry: _reload,
                  );
                }
                final mimos = (snapshot.data ?? const [])
                    .where((m) => !_hiddenIds.contains(m.id))
                    .toList();
                if (mimos.isEmpty) {
                  return _MessageState(
                    icon: Icons.favorite_border,
                    message: 'Nenhum mimo ainda.\nToque no + para salvar o primeiro.',
                    onRetry: _reload,
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                        // Max-extent (not a fixed count) so the grid gains
                        // columns on wide desktop windows instead of
                        // stretching two phone-width cards edge to edge.
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 190,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: mimos.length,
                        itemBuilder: (context, index) => MimoCard(
                          mimo: mimos[index],
                          onTap: () => _openDetail(mimos[index]),
                        ),
                      ),
                    ),
                  ),
                );
              },
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false, this.icon, this.onTap});

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? colors.ink : colors.surface,
        border: Border.all(color: selected ? colors.ink : colors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: selected ? colors.bg : colors.ink),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? colors.bg : colors.ink,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return InkWell(borderRadius: BorderRadius.circular(999), onTap: onTap, child: chip);
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message, required this.onRetry});

  final IconData icon;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: colors.inkFaint),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: colors.inkSoft)),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
          ],
        ),
      ),
    );
  }
}
