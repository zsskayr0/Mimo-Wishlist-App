import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/layout/mimo_view_mode.dart';
import '../../core/layout/view_mode_controller.dart';
import '../../core/theme/mimo_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_repository.dart';
import '../profile/edit_profile_sheet.dart';
import 'view_mode_screens.dart';

const _repoUrl = 'https://github.com/zsskayr0/Mimo-Wishlist-App';

/// Real account row, real sign-out, real theme switch and a real "Sobre"/
/// GitHub link. Push and the two privacy pickers are visual-only — "em
/// breve": nothing server-side enforces them yet, so this doesn't pretend
/// otherwise (tapping either privacy row just says so).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await UserRepository().fetchMe();
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _editProfile(UserProfile profile) async {
    // EditProfileSheet already hands back the saved profile — no need
    // for a second round-trip (and no risk of it flashing back to the
    // loading state in between).
    final updated = await EditProfileSheet.show(context, profile: profile);
    if (updated != null && mounted) setState(() => _profile = updated);
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve.')));
  }

  Future<void> _openGitHub() async {
    final messenger = ScaffoldMessenger.of(context);
    final launched = await launchUrl(Uri.parse(_repoUrl), mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Não deu pra abrir o link.')));
    }
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre o Mimo'),
        content: const Text(
          'Mimo é uma lista de desejos open-source, feita por uma pessoa só, '
          'pra organizar o que você quer comprar e compartilhar com quem quiser.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            children: [
              const Text('Configurações', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Builder(
                builder: (context) {
                  final profile = _profile;
                  final email = Supabase.instance.client.auth.currentUser?.email;
                  return _Group(
                    children: [
                      _Row(
                        leading: ClipOval(
                          child: Container(
                            width: 40,
                            height: 40,
                            color: colors.placeholder,
                            alignment: Alignment.center,
                            child: profile?.avatarUrl == null
                                ? Icon(Icons.person_outline, size: 18, color: colors.inkFaint)
                                : Image.network(profile!.avatarUrl!, fit: BoxFit.cover, width: 40, height: 40),
                          ),
                        ),
                        title: profile == null ? '—' : (profile.displayName ?? '@${profile.username}'),
                        subtitle: profile == null
                            ? null
                            : [
                                '@${profile.username}',
                                ?email,
                              ].join(' · '),
                        onTap: profile == null ? null : () => _editProfile(profile),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              _SectionLabel('Notificações'),
              const SizedBox(height: 10),
              _Group(
                children: [
                  _Row(
                    leading: _IconSquare(icon: Icons.notifications_outlined),
                    title: 'Push',
                    subtitle: 'solicitações de amizade e atividade — em breve',
                    trailing: const Switch(value: false, onChanged: null),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel('Privacidade'),
              const SizedBox(height: 10),
              _Group(
                children: [
                  _Row(
                    leading: _IconSquare(icon: Icons.lock_outline),
                    title: 'Quem pode me encontrar por @',
                    subtitle: 'Todos',
                    onTap: _comingSoon,
                  ),
                  _Divider(colors: colors),
                  _Row(
                    leading: _IconSquare(icon: Icons.person_add_alt_outlined),
                    title: 'Quem pode enviar solicitação',
                    subtitle: 'Todos',
                    onTap: _comingSoon,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel('Aparência'),
              const SizedBox(height: 10),
              _Group(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: ValueListenableBuilder<ThemeMode>(
                      valueListenable: ThemeController.instance.mode,
                      builder: (context, mode, _) {
                        return Row(
                          children: [
                            _IconSquare(icon: Icons.brightness_6_outlined),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Tema', style: TextStyle(fontWeight: FontWeight.w600))),
                            _ThemeSegment(current: mode, onChanged: ThemeController.instance.setMode),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel('Visualização'),
              const SizedBox(height: 10),
              _Group(
                children: [
                  ValueListenableBuilder<MobileMimoView>(
                    valueListenable: ViewModeController.instance.mobileMode,
                    builder: (context, mode, _) => _Row(
                      leading: _IconSquare(icon: Icons.smartphone_outlined),
                      title: 'No celular',
                      subtitle: mode.label,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MobileViewModeScreen()),
                      ),
                    ),
                  ),
                  _Divider(colors: colors),
                  ValueListenableBuilder<DesktopMimoView>(
                    valueListenable: ViewModeController.instance.desktopMode,
                    builder: (context, mode, _) => _Row(
                      leading: _IconSquare(icon: Icons.desktop_windows_outlined),
                      title: 'No desktop',
                      subtitle: mode.label,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DesktopViewModeScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel('Sobre'),
              const SizedBox(height: 10),
              _Group(
                children: [
                  _Row(
                    leading: _IconSquare(icon: Icons.info_outline),
                    title: 'Sobre o Mimo',
                    onTap: _showAbout,
                  ),
                  _Divider(colors: colors),
                  _Row(
                    leading: _IconSquare(icon: Icons.code_rounded),
                    title: 'Código aberto no GitHub',
                    onTap: _openGitHub,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _Group(
                children: [
                  _Row(
                    leading: _IconSquare(icon: Icons.logout, color: Colors.red),
                    title: 'Sair',
                    titleColor: Colors.red,
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
                      version == null ? 'Mimo' : 'Mimo · $version',
                      style: TextStyle(fontSize: 11.5, color: colors.inkFaint),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
        color: MimoColors.of(context).inkFaint,
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

class _Divider extends StatelessWidget {
  const _Divider({required this.colors});

  final MimoColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: colors.border),
    );
  }
}

class _IconSquare extends StatelessWidget {
  const _IconSquare({required this.icon, this.color = MimoColors.gradientA});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Icon(icon, size: 17, color: color),
    );
  }
}

/// One "icon square + title [+ subtitle] [+ trailing]" row — the shape
/// every card in the reference shares, whether the trailing bit is a
/// chevron (tappable) or a disabled switch (not, yet).
class _Row extends StatelessWidget {
  const _Row({
    required this.leading,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(fontSize: 12, color: colors.inkFaint)),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right, color: colors.inkFaint, size: 20),
          ],
        ),
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
          for (final option in _options) _segment(colors, option.mode, option.label),
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
