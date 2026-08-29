import 'package:flutter/material.dart';

/// Shared palette, kept in step with the product wireframes so the app and
/// the design docs never drift apart.
class MimoColors {
  MimoColors._();

  static const ink = Color(0xFF1D1733);
  static const inkSoft = Color(0xFF6F6884);
  static const inkFaint = Color(0xFFA8A2BC);
  static const bg = Color(0xFFF4F3F7);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE3DFEC);
  static const placeholder = Color(0xFFDAD5E6);

  static const gradientA = Color(0xFF6C5CE0);
  static const gradientB = Color(0xFFEC6FA8);
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientA, gradientB],
  );

  static const tagGray = Color(0xFF6F6884);
  static const tagGrayBg = Color(0xFFECE9F2);
  static const tagGold = Color(0xFF8C6A1E);
  static const tagGoldBg = Color(0xFFF3E4C4);
  static const tagPlum = Color(0xFF8B4F9E);
  static const tagPlumBg = Color(0xFFF1E1F5);
  static const tagSage = Color(0xFF3F7A5C);
  static const tagSageBg = Color(0xFFDCEFE4);

  // Auth screen only — dark panel, kept separate from the light palette
  // the rest of the app uses.
  static const authBg = Color(0xFF100D1A);
  static const authPanel = Color(0xFF17131F);
  static const authInputBg = Color(0xFF1B1726);
  static const authBorder = Color(0xFF2C2640);
  static const authText = Color(0xFFF4F1FA);
  static const authPlaceholder = Color(0xFF7C7398);
}
