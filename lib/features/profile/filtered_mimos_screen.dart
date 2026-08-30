import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/models/mimo.dart';
import '../../data/repositories/mimo_repository.dart';
import '../feed/widgets/mimo_card.dart';
import '../mimo_detail/mimo_detail_screen.dart';

/// Generic "N mimos matching some predicate" list — backs the Perfil
/// screen's Resumo/Histórico cards (desorganizados, comprados,
/// arquivados) without needing a dedicated screen for each one.
class FilteredMimosScreen extends StatefulWidget {
  const FilteredMimosScreen({super.key, required this.title, required this.filter});

  final String title;
  final bool Function(Mimo) filter;

  @override
  State<FilteredMimosScreen> createState() => _FilteredMimosScreenState();
}

class _FilteredMimosScreenState extends State<FilteredMimosScreen> {
  final _repository = MimoRepository();
  late Future<List<Mimo>> _mimosFuture;
  final Set<String> _hiddenIds = {};

  @override
  void initState() {
    super.initState();
    _mimosFuture = _repository.fetchFeed();
  }

  Future<void> _reload() async {
    final future = _repository.fetchFeed();
    setState(() {
      _mimosFuture = future;
    });
    await future;
    if (mounted) setState(_hiddenIds.clear);
  }

  Future<void> _openDetail(Mimo mimo) async {
    final deleted = await MimoDetailScreen.open(context, mimo: mimo);
    if (deleted == true) setState(() => _hiddenIds.add(mimo.id));
    _reload();
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
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Mimo>>(
        future: _mimosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final mimos = (snapshot.data ?? const [])
              .where((m) => !_hiddenIds.contains(m.id))
              .where(widget.filter)
              .toList();
          if (mimos.isEmpty) {
            return Center(
              child: Text('Nada por aqui ainda.', style: TextStyle(color: colors.inkSoft)),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: MasonryGridView.extent(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  maxCrossAxisExtent: 190,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
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
    );
  }
}
