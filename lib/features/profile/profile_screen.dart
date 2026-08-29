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
    final colors = MimoColors.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username'] as String?;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 110),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(color: colors.placeholder, shape: BoxShape.circle),
                  child: Icon(Icons.person_outline, size: 30, color: colors.inkFaint),
                ),
                const SizedBox(height: 12),
                Text(
                  username != null ? '@$username' : (user?.email ?? 'Perfil'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (username != null && user?.email != null) ...[
                  const SizedBox(height: 2),
                  Text(user!.email!, style: TextStyle(fontSize: 12.5, color: colors.inkFaint)),
                ],
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
                  color: colors.surface,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      count == null ? '—' : '$count',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text('mimos salvos', style: TextStyle(fontSize: 12, color: colors.inkFaint)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Pastas, amigos e histórico de compra chegam nas próximas etapas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.inkFaint, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
