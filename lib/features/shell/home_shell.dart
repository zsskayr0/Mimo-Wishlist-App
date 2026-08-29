import 'dart:ui';

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

/// Chrome corner radius for the floating nav — bottom bar and sidebar both
/// use it, so the two stay visually one system across the breakpoint.
const _navRadius = 8.0;

/// The app's chrome: Feed/Amigos/Perfil/Config plus the universal capture
/// button, in two shapes picked by width (see [MimoBreakpoints]) — both
/// floating (inset from the screen edge, blurred, rounded) rather than
/// docked flush to it. Bumping [_feedRefreshTick] re-keys FeedScreen so it
/// refetches after a successful capture, without reaching for a
/// state-management package for one signal.
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
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(padding: const EdgeInsets.only(left: 264), child: content),
                    ),
                    Positioned(
                      left: 16,
                      top: 16,
                      bottom: 16,
                      child: _FloatingSidebar(
                        currentIndex: _tabIndex,
                        onTabSelected: (index) => setState(() => _tabIndex = index),
                        onAddPressed: _openCapture,
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Positioned.fill(child: content),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _FloatingBottomBar(
                          currentIndex: _tabIndex,
                          onTabSelected: (index) => setState(() => _tabIndex = index),
                          onAddPressed: _openCapture,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _FloatingSidebar extends StatelessWidget {
  const _FloatingSidebar({
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
      decoration: BoxDecoration(
        color: MimoColors.surface,
        borderRadius: BorderRadius.circular(_navRadius),
        border: Border.all(color: MimoColors.border),
        boxShadow: [
          BoxShadow(color: MimoColors.ink.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_navRadius)),
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
        borderRadius: BorderRadius.circular(_navRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(_navRadius),
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

class _FloatingBottomBar extends StatelessWidget {
  const _FloatingBottomBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_navRadius),
            boxShadow: [
              BoxShadow(color: MimoColors.ink.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_navRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: MimoColors.surface.withValues(alpha: 0.78),
                  border: Border.all(color: MimoColors.border.withValues(alpha: 0.7)),
                  borderRadius: BorderRadius.circular(_navRadius),
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
            ),
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
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 20, color: color),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
