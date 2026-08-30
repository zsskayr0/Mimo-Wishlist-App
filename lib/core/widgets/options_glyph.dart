import 'package:flutter/material.dart';

import '../theme/mimo_colors.dart';

/// The small square "•••" glyph used for an "options" trigger — shared
/// between MimoDetailScreen (a `PopupMenuButton`'s child) and
/// FolderDetailScreen's "Opções da pasta" button (an `InkWell`'s child),
/// so both look identical regardless of what opens on tap.
class OptionsGlyph extends StatelessWidget {
  const OptionsGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.more_horiz, size: 18, color: colors.ink),
    );
  }
}
