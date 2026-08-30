import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/layout/mimo_view_mode.dart';
import '../../core/layout/view_mode_controller.dart';
import '../../core/theme/mimo_colors.dart';
import 'view_mode_preview.dart';

/// "esse menu é uma página nova, não sendo um menu flutuante" — a real
/// pushed page, not a sheet/dialog like the rest of the app's pickers.
class MobileViewModeScreen extends StatelessWidget {
  const MobileViewModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ViewModeSelectScreen<MobileMimoView>(
      title: 'Visualização no celular',
      values: MobileMimoView.values,
      labelOf: (v) => v.label,
      shapeOf: (v) => switch (v) {
        MobileMimoView.list => ViewModeShape.list,
        MobileMimoView.detailedList => ViewModeShape.detailedList,
        MobileMimoView.grid2 || MobileMimoView.grid3 => ViewModeShape.grid,
      },
      columnsOf: (v) => v == MobileMimoView.grid3 ? 3 : 2,
      listenable: ViewModeController.instance.mobileMode,
      onSelected: ViewModeController.instance.setMobileMode,
    );
  }
}

class DesktopViewModeScreen extends StatelessWidget {
  const DesktopViewModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ViewModeSelectScreen<DesktopMimoView>(
      title: 'Visualização no desktop',
      values: DesktopMimoView.values,
      labelOf: (v) => v.label,
      shapeOf: (v) => switch (v) {
        DesktopMimoView.list => ViewModeShape.list,
        DesktopMimoView.detailedList => ViewModeShape.detailedList,
        DesktopMimoView.table => ViewModeShape.table,
        DesktopMimoView.dynamicGrid => ViewModeShape.dynamicGrid,
      },
      columnsOf: (_) => 3,
      listenable: ViewModeController.instance.desktopMode,
      onSelected: ViewModeController.instance.setDesktopMode,
    );
  }
}

class _ViewModeSelectScreen<T> extends StatelessWidget {
  const _ViewModeSelectScreen({
    required this.title,
    required this.values,
    required this.labelOf,
    required this.shapeOf,
    required this.columnsOf,
    required this.listenable,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final String Function(T) labelOf;
  final ViewModeShape Function(T) shapeOf;
  final int Function(T) columnsOf;
  final ValueListenable<T> listenable;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = MimoColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(title),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ValueListenableBuilder<T>(
            valueListenable: listenable,
            builder: (context, current, _) {
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: values.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final value = values[index];
                  final selected = value == current;
                  return _OptionRow(
                    label: labelOf(value),
                    selected: selected,
                    preview: ViewModePreview(shape: shapeOf(value), columns: columnsOf(value)),
                    onTap: () => onSelected(value),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.selected, required this.preview, required this.onTap});

  final String label;
  final bool selected;
  final Widget preview;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? MimoColors.gradientA : colors.border, width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              preview,
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? MimoColors.gradientA : colors.inkFaint,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
