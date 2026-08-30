import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/theme/mimo_colors.dart';
import '../../core/widgets/mimo_mark.dart';
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
/// docked flush to it. On mobile the tabs live in a `PageView` so they're
/// swipeable (Instagram-style) as well as tap-able; each tab is wrapped in
/// [_KeepAlive] so swiping away and back doesn't lose scroll position or
/// force a reload — the same guarantee `IndexedStack` gave on desktop.
/// Bumping [_feedRefreshTick] re-keys FeedScreen so it refetches after a
/// successful capture, without reaching for a state-management package for
/// one signal.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;
  int _feedRefreshTick = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Nav-bar taps jump instantly (no slide-through-intermediate-pages
  /// animation) — matches how a tap is expected to behave versus a drag;
  /// swiping itself is already smooth via PageView's own physics. Guarded
  /// for desktop, where the PageView (and so the controller) isn't built.
  void _goToTab(int index) {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
    setState(() => _tabIndex = index);
  }

  Future<void> _openCapture() async {
    final saved = await QuickCaptureSheet.show(context);
    if (saved == true) {
      setState(() => _feedRefreshTick++);
      _goToTab(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    final tabs = [
      _KeepAlive(child: FeedScreen(key: ValueKey('feed-$_feedRefreshTick'))),
      const _KeepAlive(child: FriendsScreen()),
      const _KeepAlive(child: ProfileScreen()),
      const _KeepAlive(child: SettingsScreen()),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = MimoBreakpoints.isDesktop(constraints.maxWidth);
        final content = desktop
            ? IndexedStack(index: _tabIndex, children: tabs)
            : PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _tabIndex = index),
                children: tabs,
              );
        return Scaffold(
          backgroundColor: colors.bg,
          body: desktop
              ? Stack(
                  children: [
                    Positioned.fill(
                      // Matches the sidebar's own 16px inset so content
                      // starts flush with it instead of sitting higher —
                      // the mismatch read as a stray edge poking out above
                      // the sidebar's rounded top corner.
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(264, 16, 16, 16),
                        child: content,
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 16,
                      bottom: 16,
                      child: _FloatingSidebar(
                        currentIndex: _tabIndex,
                        onTabSelected: _goToTab,
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
                          onTabSelected: _goToTab,
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

/// Keeps a tab's state alive while a sibling page is showing in the
/// `PageView` — without this, swiping a tab off-screen disposes it like a
/// `ListView` item would, losing scroll position and forcing a reload the
/// moment the user swipes back.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
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
    final colors = MimoColors.of(context);
    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_navRadius),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(color: colors.ink.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8)),
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
                child: const MimoMark(size: 28),
              ),
              const SizedBox(width: 10),
              Text('Mimo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.ink)),
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
          for (var i = 0; i < _destinations.length; i++) _railItem(colors, i),
        ],
      ),
    );
  }

  Widget _railItem(MimoColors colors, int index) {
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
                Icon(item.icon, size: 20, color: active ? MimoColors.gradientA : colors.inkSoft),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: active ? MimoColors.gradientA : colors.inkSoft,
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
    final colors = MimoColors.of(context);
    return Container(
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_navRadius),
        boxShadow: [
          BoxShadow(color: colors.ink.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_navRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.78),
              border: Border.all(color: colors.border.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(_navRadius),
            ),
            child: Row(
              children: [
                _navItem(colors, 0),
                _navItem(colors, 1),
                _addItem(),
                _navItem(colors, 2),
                _navItem(colors, 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(MimoColors colors, int index) {
    final item = _destinations[index];
    final active = index == currentIndex;
    final color = active ? MimoColors.gradientA : colors.inkFaint;

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

  /// Inline, vertically centered alongside the tabs — not a raised FAB
  /// poking above the bar. (The old raised-circle version also had a real
  /// bug: half its hit area sat outside the enclosing Stack's own layout
  /// bounds, so only the icon glyph near the bar's top edge reliably
  /// registered taps. `Material`+`InkWell` with a `CircleBorder` here
  /// gives the whole circle a correctly matching hit area.)
  Widget _addItem() {
    return Expanded(
      child: Center(
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onAddPressed,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(gradient: MimoColors.gradient, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
