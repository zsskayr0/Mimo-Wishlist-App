import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/mimo_colors.dart';

/// Real sign-out; notifications/privacy/theme/about wait on their own
/// features (push is deferred past the MVP — see CHANGELOG/roadmap).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 110),
        children: [
          const Text('Configurações', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Material(
            color: MimoColors.surface,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: MimoColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.person_outline, color: MimoColors.gradientA),
                title: Text(user?.email ?? 'Conta'),
                subtitle: const Text('Notificações, privacidade e tema — em breve'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: MimoColors.surface,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: MimoColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sair', style: TextStyle(color: Colors.red)),
                onTap: () => Supabase.instance.client.auth.signOut(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version;
                return Text(
                  version == null ? 'Mimo' : 'Mimo · versão $version',
                  style: const TextStyle(fontSize: 11.5, color: MimoColors.inkFaint),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
