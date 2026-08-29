import 'package:flutter/material.dart';

/// Brightness-aware palette. `MimoColors.of(context)` resolves to [light] or
/// [dark] off `Theme.of(context).brightness`, which MaterialApp's
/// `theme`/`darkTheme`/`themeMode` already drive — nothing here needs to
/// know about the Settings toggle directly.
///
/// The auth screen (login/cadastro) is a deliberate fixed dark composition
/// matching a supplied reference — it uses its own `auth*` constants below,
/// not this brightness switch.
class MimoColors {
  const MimoColors._({
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.bg,
    required this.surface,
    required this.border,
    required this.placeholder,
    required this.tagGray,
    required this.tagGrayBg,
    required this.tagGold,
    required this.tagGoldBg,
    required this.tagPlum,
    required this.tagPlumBg,
    required this.tagSage,
    required this.tagSageBg,
  });

  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color bg;
  final Color surface;
  final Color border;
  final Color placeholder;
  final Color tagGray;
  final Color tagGrayBg;
  final Color tagGold;
  final Color tagGoldBg;
  final Color tagPlum;
  final Color tagPlumBg;
  final Color tagSage;
  final Color tagSageBg;

  static MimoColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static const light = MimoColors._(
    ink: Color(0xFF1D1733),
    inkSoft: Color(0xFF6F6884),
    inkFaint: Color(0xFFA8A2BC),
    bg: Color(0xFFF4F3F7),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE3DFEC),
    placeholder: Color(0xFFDAD5E6),
    tagGray: Color(0xFF6F6884),
    tagGrayBg: Color(0xFFECE9F2),
    tagGold: Color(0xFF8C6A1E),
    tagGoldBg: Color(0xFFF3E4C4),
    tagPlum: Color(0xFF8B4F9E),
    tagPlumBg: Color(0xFFF1E1F5),
    tagSage: Color(0xFF3F7A5C),
    tagSageBg: Color(0xFFDCEFE4),
  );

  /// True AMOLED black background, on purpose — not a dark grey.
  static const dark = MimoColors._(
    ink: Color(0xFFF4F1FA),
    inkSoft: Color(0xFFB7AECF),
    inkFaint: Color(0xFF7C7398),
    bg: Color(0xFF000000),
    surface: Color(0xFF0E0C14),
    border: Color(0xFF241F30),
    placeholder: Color(0xFF2A2436),
    tagGray: Color(0xFFACA4C4),
    tagGrayBg: Color(0xFF2C2640),
    tagGold: Color(0xFFE0B458),
    tagGoldBg: Color(0xFF3C2F1B),
    tagPlum: Color(0xFFD19CE0),
    tagPlumBg: Color(0xFF3A2A44),
    tagSage: Color(0xFF9BC29A),
    tagSageBg: Color(0xFF223A2E),
  );

  // Brand gradient — same two stops in both modes; already reads well on
  // both a light card and true black.
  static const gradientA = Color(0xFF6C5CE0);
  static const gradientB = Color(0xFFEC6FA8);
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientA, gradientB],
  );

  // Auth screen only — see class doc.
  static const authBg = Color(0xFF100D1A);
  static const authPanel = Color(0xFF17131F);
  static const authInputBg = Color(0xFF1B1726);
  static const authBorder = Color(0xFF2C2640);
  static const authText = Color(0xFFF4F1FA);
  static const authPlaceholder = Color(0xFF7C7398);
}
