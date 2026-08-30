import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../../core/widgets/grid_dynamic_icon.dart';
import '../../data/models/mimo.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/friendship_repository.dart';
import '../../data/repositories/mimo_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'edit_profile_sheet.dart';
import 'filtered_mimos_screen.dart';

class _ProfileData {
  const _ProfileData({
    required this.profile,
    required this.mimoCount,
    required this.folderCount,
    required this.friendCount,
    required this.unorganizedCount,
    required this.comprados,
    required this.arquivados,
  });

  final UserProfile profile;
  final int mimoCount;
  final int folderCount;
  final int friendCount;
  final int unorganizedCount;
  final int comprados;
  final int arquivados;

  _ProfileData withProfile(UserProfile profile) => _ProfileData(
        profile: profile,
        mimoCount: mimoCount,
        folderCount: folderCount,
        friendCount: friendCount,
        unorganizedCount: unorganizedCount,
        comprados: comprados,
        arquivados: arquivados,
      );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Null only before the first load ever completes — see FeedScreen for
  /// why this is cached state instead of a bare Future+FutureBuilder.
  _ProfileData? _data;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        UserRepository().fetchMe(),
        MimoRepository().fetchFeed(),
        FolderRepository().fetchFolders(),
        FriendshipRepository().fetchFriends(),
      ]);
      final profile = results[0] as UserProfile;
      final mimos = results[1] as List<Mimo>;
      final folders = results[2] as List;
      final friends = results[3] as List;

      if (!mounted) return;
      setState(() {
        _data = _ProfileData(
          profile: profile,
          mimoCount: mimos.length,
          folderCount: folders.length,
          friendCount: friends.length,
          unorganizedCount: mimos.where((m) => m.isUnorganized).length,
          comprados: mimos.where((m) => m.purchaseStatus == 'comprado').length,
          arquivados: mimos.where((m) => m.purchaseStatus == 'arquivado').length,
        );
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_data == null) {
        setState(() => _loadError = e);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não deu pra atualizar o perfil.')),
        );
      }
    }
  }

  Future<void> _editProfile(UserProfile profile) async {
    // EditProfileSheet already hands back the saved profile — swap it
    // straight into the cached data instead of a full reload.
    final updated = await EditProfileSheet.show(context, profile: profile);
    if (updated != null && mounted) {
      setState(() => _data = _data?.withProfile(updated));
    }
  }

  void _openFiltered(String title, bool Function(Mimo) filter) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FilteredMimosScreen(title: title, filter: filter)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return SafeArea(child: _buildBody(colors));
  }

  Widget _buildBody(MimoColors colors) {
    if (_data == null && _loadError == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_data == null && _loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Não deu pra carregar o perfil.', style: TextStyle(color: colors.inkSoft)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Tentar de novo')),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    final profile = data.profile;

    return RefreshIndicator(
      onRefresh: _load,
      child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                  children: [
                    const Text('Perfil', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          ClipOval(
                            child: Container(
                              width: 76,
                              height: 76,
                              color: colors.placeholder,
                              alignment: Alignment.center,
                              child: profile.avatarUrl == null
                                  ? Icon(Icons.person_outline, size: 30, color: colors.inkFaint)
                                  : Image.network(profile.avatarUrl!, fit: BoxFit.cover, width: 76, height: 76),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile.displayName ?? '@${profile.username}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text('@${profile.username}', style: TextStyle(fontSize: 13, color: colors.inkFaint)),
                          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                profile.bio!,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: colors.inkSoft, height: 1.4),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () => _editProfile(profile),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Editar perfil', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _StatCard(value: data.mimoCount, label: 'mimos')),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(value: data.folderCount, label: 'pastas')),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(value: data.friendCount, label: 'amigos')),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel('Resumo'),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      icon: (color) => GridDynamicIcon(color: color, size: 18),
                      title: '${data.unorganizedCount} ${data.unorganizedCount == 1 ? 'mimo' : 'mimos'} desorganizados',
                      subtitle: 'arraste pra uma pasta quando quiser',
                      onTap: () => _openFiltered('Desorganizados', (m) => m.isUnorganized),
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel('Histórico'),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      iconData: Icons.check_circle_outline,
                      title: 'Mimos comprados',
                      subtitle: '${data.comprados} ${data.comprados == 1 ? 'item' : 'itens'}',
                      onTap: () => _openFiltered('Mimos comprados', (m) => m.purchaseStatus == 'comprado'),
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      iconData: Icons.folder_outlined,
                      title: 'Mimos arquivados',
                      subtitle: '${data.arquivados} ${data.arquivados == 1 ? 'item' : 'itens'}',
                      onTap: () => _openFiltered('Mimos arquivados', (m) => m.purchaseStatus == 'arquivado'),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: colors.inkFaint)),
        ],
      ),
    );
  }
}

/// One "icon square + bold title + gray subtitle [+ chevron]" row — the
/// shape every card in the wireframe's Resumo/Histórico sections share.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    this.iconData,
    this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  }) : assert(iconData != null || icon != null, 'need either iconData or icon');

  final IconData? iconData;

  /// For a non-Material icon (e.g. the SVG dynamic-covers glyph).
  final Widget Function(Color color)? icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: MimoColors.gradientA.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: icon != null
                    ? icon!(MimoColors.gradientA)
                    : Icon(iconData, color: MimoColors.gradientA, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: colors.inkFaint)),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.chevron_right, color: colors.inkFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
