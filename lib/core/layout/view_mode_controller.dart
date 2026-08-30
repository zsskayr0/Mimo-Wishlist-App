import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mimo_view_mode.dart';

/// Persists the Feed/Pasta view-mode choice (Settings → Visualização),
/// separately for mobile and desktop width — same idea and lifecycle as
/// `ThemeController`. Both default to a grid, matching how the app looked
/// before this setting existed.
class ViewModeController {
  ViewModeController._(this.mobileMode, this.desktopMode);

  static const _mobileKey = 'mimo_mobile_view';
  static const _desktopKey = 'mimo_desktop_view';

  final ValueNotifier<MobileMimoView> mobileMode;
  final ValueNotifier<DesktopMimoView> desktopMode;

  static late final ViewModeController instance;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMobile = prefs.getString(_mobileKey);
    final mobile = MobileMimoView.values.firstWhere(
      (m) => m.name == savedMobile,
      orElse: () => MobileMimoView.grid2,
    );

    final savedDesktop = prefs.getString(_desktopKey);
    final desktop = DesktopMimoView.values.firstWhere(
      (m) => m.name == savedDesktop,
      orElse: () => DesktopMimoView.dynamicGrid,
    );

    instance = ViewModeController._(ValueNotifier(mobile), ValueNotifier(desktop));
  }

  Future<void> setMobileMode(MobileMimoView mode) async {
    mobileMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mobileKey, mode.name);
  }

  Future<void> setDesktopMode(DesktopMimoView mode) async {
    desktopMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_desktopKey, mode.name);
  }
}
