import 'package:flutter/material.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/theme/mimo_colors.dart';
import '../capture/quick_capture_sheet.dart';
import '../feed/feed_screen.dart';
import '../friends/friends_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

const _destinations = [
  (icon: Icons.grid_view_rounded, label: 'Feed'),
  (icon: Icons.people_outline, label: 'Amigos'),
  (icon: Icons.person_outline, label: 'Perfil'),
  (icon: Icons.tune, label: 'Config'),
];

/// The app's chrome: Feed/Amigos/Perfil/Config plus the universal capture
/// button, in two shapes picked by width (see [MimoBreakpoints]) —
/// a bottom bar with a raised center button on phones, a left sidebar with
/// a labelled button on desktop. Both wrap the same screens, so behaviour
/// never depends on which chrome is showing.
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
    final content = IndexedStack(index: _tabIndex, children: tabs);

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = MimoBreakpoints.isDesktop(constraints.maxWidth);
        return Scaffold(
          backgroundColor: MimoColors.bg,
          body: desktop
              ? Row(
                  children: [
                    _Sidebar(
                      currentIndex: _tabIndex,
                      onTabSelected: (index) => setState(() => _tabIndex = index),
                      onAddPressed: _openCapture,
                    ),
                    const VerticalDivider(width: 1, color: MimoColors.border),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: desktop
              ? null
              : _BottomBar(
                  currentIndex: _tabIndex,
                  onTabSelected: (index) => setState(() => _tabIndex = index),
                  onAddPressed: _openCapture,
                ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      color: MimoColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: MimoColors.gradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              const Text('Mimo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onAddPressed,
            style: FilledButton.styleFrom(
              backgroundColor: MimoColors.gradientA,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Novo mimo'),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < _destinations.length; i++) _railItem(i),
        ],
      ),
    );
  }

  Widget _railItem(int index) {
    final item = _destinations[index];
    final active = index == currentIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? MimoColors.gradientA.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTabSelected(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: active ? MimoColors.gradientA : MimoColors.inkSoft),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: active ? MimoColors.gradientA : MimoColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final item = _destinations[index];
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
