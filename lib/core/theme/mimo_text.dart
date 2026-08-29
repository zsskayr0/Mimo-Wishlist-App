import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Builds the app's Poppins [TextTheme], explicitly instantiating each
/// weight role through `GoogleFonts.poppins(fontWeight: ...)` rather than
/// `GoogleFonts.poppinsTextTheme()` alone — the latter only touches the two
/// or three weights Material's default roles use, so anything elsewhere in
/// the app asking for a weight that was never registered (a light caption,
/// a heavy title) would fall back to synthetic faux-bold instead of the
/// real Poppins file. Registering the full range here once means every
/// bare `TextStyle(fontWeight: ...)` in the app inherits the right face —
/// `Text` merges its style onto the ambient `DefaultTextStyle`, which
/// Material seeds from `Theme.textTheme`, so this needs setting in exactly
/// one place (see `theme`/`darkTheme` in main.dart).
TextTheme poppinsTextTheme(TextTheme base) {
  TextStyle weight(FontWeight w, TextStyle? style) =>
      GoogleFonts.poppins(textStyle: style, fontWeight: w);

  return base.copyWith(
    displayLarge: weight(FontWeight.w700, base.displayLarge),
    displayMedium: weight(FontWeight.w700, base.displayMedium),
    displaySmall: weight(FontWeight.w700, base.displaySmall),
    headlineLarge: weight(FontWeight.w600, base.headlineLarge),
    headlineMedium: weight(FontWeight.w600, base.headlineMedium),
    headlineSmall: weight(FontWeight.w600, base.headlineSmall),
    titleLarge: weight(FontWeight.w600, base.titleLarge),
    titleMedium: weight(FontWeight.w600, base.titleMedium),
    titleSmall: weight(FontWeight.w500, base.titleSmall),
    bodyLarge: weight(FontWeight.w400, base.bodyLarge),
    bodyMedium: weight(FontWeight.w400, base.bodyMedium),
    bodySmall: weight(FontWeight.w300, base.bodySmall),
    labelLarge: weight(FontWeight.w500, base.labelLarge),
    labelMedium: weight(FontWeight.w500, base.labelMedium),
    labelSmall: weight(FontWeight.w300, base.labelSmall),
  );
}
