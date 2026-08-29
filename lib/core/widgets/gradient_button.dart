import 'package:flutter/material.dart';

import '../theme/mimo_colors.dart';

/// The app's one primary-action button. `FilledButton.styleFrom` only
/// paints a solid `backgroundColor` — passing it `MimoColors.gradientA`
/// alone renders flat, never the two-stop gradient the wireframes show.
/// `Ink` is what actually lets a `BoxDecoration.gradient` sit under an
/// `InkWell`'s ripple.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 15),
    this.borderRadius = 13,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(gradient: MimoColors.gradient, borderRadius: radius),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Padding(
              padding: padding,
              child: Center(
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  child: IconTheme.merge(data: const IconThemeData(color: Colors.white, size: 16), child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
