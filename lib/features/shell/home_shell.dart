import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';
import '../capture/quick_capture_sheet.dart';
import '../feed/feed_screen.dart';
import '../friends/friends_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

/// The 4-tab bottom nav (Feed, Amigos, Perfil, Configurações) with the
/// universal capture button raised in the center, between Amigos and
/// Perfil — mirrors the wireframes exactly. Bumping [_feedRefreshTick]
/// re-keys FeedScreen so it refetches after a successful capture, without
/// reaching for a state-management package for one signal.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;
  int _feedRefreshTick = 0;

  Future<void> _openCapture() async {
    final saved = await QuickCaptureSheet.show(context);
    if (saved == true) {
      setState(() {
        _tabIndex = 0;
        _feedRefreshTick++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      FeedScreen(key: ValueKey('feed-$_feedRefreshTick')),
      const FriendsScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: MimoColors.bg,
      body: IndexedStack(index: _tabIndex, children: tabs),
      bottomNavigationBar: _BottomBar(
        currentIndex: _tabIndex,
        onTabSelected: (index) => setState(() => _tabIndex = index),
        onAddPressed: _openCapture,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  static const _items = [
    (icon: Icons.grid_view_rounded, label: 'Feed'),
    (icon: Icons.people_outline, label: 'Amigos'),
    (icon: Icons.person_outline, label: 'Perfil'),
    (icon: Icons.tune, label: 'Config'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 78,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: MimoColors.surface,
                border: Border(top: BorderSide(color: MimoColors.border)),
              ),
              child: Row(
                children: [
                  _navItem(0),
                  _navItem(1),
                  const Expanded(child: SizedBox()),
                  _navItem(2),
                  _navItem(3),
                ],
              ),
            ),
            Positioned(
              top: -26,
              child: GestureDetector(
                onTap: onAddPressed,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: MimoColors.gradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: MimoColors.bg, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: MimoColors.gradientA.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index) {
    final item = _items[index];
    final active = index == currentIndex;
    final color = active ? MimoColors.gradientA : MimoColors.inkFaint;

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 21, color: color),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
