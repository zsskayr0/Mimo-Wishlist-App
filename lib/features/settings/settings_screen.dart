import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/mimo_colors.dart';
import '../../core/theme/theme_controller.dart';

/// Real sign-out and a real theme switch; notifications/privacy wait on
/// their own features (push is deferred past the MVP — see
/// CHANGELOG/roadmap).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 110),
        children: [
          const Text('Configurações', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _Group(
            children: [
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.person_outline, color: MimoColors.gradientA),
                title: Text(user?.email ?? 'Conta'),
                subtitle: const Text('Notificações e privacidade — em breve'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'APARÊNCIA',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: colors.inkFaint),
          ),
          const SizedBox(height: 10),
          _Group(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeController.instance.mode,
                  builder: (context, mode, _) {
                    return Row(
                      children: [
                        Icon(Icons.brightness_6_outlined, size: 18, color: MimoColors.gradientA),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Tema', style: TextStyle(fontWeight: FontWeight.w600))),
                        _ThemeSegment(
                          current: mode,
                          onChanged: ThemeController.instance.setMode,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Group(
            children: [
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sair', style: TextStyle(color: Colors.red)),
                onTap: () => Supabase.instance.client.auth.signOut(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version;
                return Text(
                  version == null ? 'Mimo' : 'Mimo · versão $version',
                  style: TextStyle(fontSize: 11.5, color: colors.inkFaint),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  const _ThemeSegment({required this.current, required this.onChanged});

  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  static const _options = [
    (mode: ThemeMode.light, label: 'Claro'),
    (mode: ThemeMode.dark, label: 'Escuro'),
    (mode: ThemeMode.system, label: 'Sistema'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in _options)
            _segment(colors, option.mode, option.label),
        ],
      ),
    );
  }

  Widget _segment(MimoColors colors, ThemeMode mode, String label) {
    final active = mode == current;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [BoxShadow(color: colors.ink.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: active ? colors.ink : colors.inkFaint,
          ),
        ),
      ),
    );
  }
}
