import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/mimo_colors.dart';
import '../../data/repositories/mimo_repository.dart';

/// Real identity (from the auth session) and a real mimo count; folder and
/// friend counts wait on those features' repositories.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<int> _mimoCountFuture;

  @override
  void initState() {
    super.initState();
    _mimoCountFuture = MimoRepository().fetchFeed().then((mimos) => mimos.length);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(color: MimoColors.placeholder, shape: BoxShape.circle),
                  child: const Icon(Icons.person_outline, size: 30, color: MimoColors.inkFaint),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.email ?? 'Perfil',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<int>(
            future: _mimoCountFuture,
            builder: (context, snapshot) {
              final count = snapshot.data;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: MimoColors.surface,
                  border: Border.all(color: MimoColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      count == null ? '—' : '$count',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    const Text('mimos salvos', style: TextStyle(fontSize: 12, color: MimoColors.inkFaint)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Pastas, amigos e histórico de compra chegam nas próximas etapas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: MimoColors.inkFaint, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
