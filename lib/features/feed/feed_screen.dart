import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/mimo.dart';
import '../../data/repositories/mimo_repository.dart';
import 'widgets/mimo_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _repository = MimoRepository();
  late Future<List<Mimo>> _feedFuture;

  @override
  void initState() {
    super.initState();
    _feedFuture = _repository.fetchFeed();
  }

  Future<void> _reload() async {
    final future = _repository.fetchFeed();
    setState(() => _feedFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
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
                const Text('Mimo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                color: MimoColors.surface,
                border: Border.all(color: MimoColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: MimoColors.inkFaint),
                  const SizedBox(width: 10),
                  Text(
                    'Buscar mimos ou @usuário',
                    style: TextStyle(color: MimoColors.inkFaint, fontSize: 14),
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
              children: const [
                _FilterChip(label: 'Todos', selected: true),
                SizedBox(width: 8),
                _FilterChip(label: 'Casa'),
                SizedBox(width: 8),
                _FilterChip(label: 'Tech'),
                SizedBox(width: 8),
                _FilterChip(label: 'Roupas'),
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
                final mimos = snapshot.data ?? const [];
                if (mimos.isEmpty) {
                  return _MessageState(
                    icon: Icons.favorite_border,
                    message: 'Nenhum mimo ainda.\nToque no + para salvar o primeiro.',
                    onRetry: _reload,
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: mimos.length,
                    itemBuilder: (context, index) => MimoCard(mimo: mimos[index]),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: MimoColors.surface,
          border: Border.all(color: MimoColors.border),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 18, color: MimoColors.ink),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? MimoColors.ink : MimoColors.surface,
        border: Border.all(color: selected ? MimoColors.ink : MimoColors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : MimoColors.ink,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message, required this.onRetry});

  final IconData icon;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: MimoColors.inkFaint),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: MimoColors.inkSoft)),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
          ],
        ),
      ),
    );
  }
}
