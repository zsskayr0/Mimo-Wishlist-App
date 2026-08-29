/// Single source of truth for where the app switches from a phone-shaped
/// layout to a desktop-shaped one. Follows Material 3's "expanded" window
/// size class (>=840dp) rather than a Mimo-specific number, since it's a
/// well-tested threshold: wide enough that a side rail reads naturally,
/// narrow enough to still catch a snapped/half window on Windows.
class MimoBreakpoints {
  MimoBreakpoints._();

  static const double desktop = 840;

  static bool isDesktop(double width) => width >= desktop;
}
