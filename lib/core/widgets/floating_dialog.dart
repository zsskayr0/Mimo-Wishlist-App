import 'package:flutter/material.dart';

/// Presents [builder]'s content as a centered floating dialog that closes
/// when the user taps anywhere outside it.
///
/// Flutter's own `Dialog` widget doesn't give that for free here: its
/// `Material` wrapper hit-tests its *entire* bounds — including the
/// transparent margin around the actual card — which swallows the tap
/// before it ever reaches the barrier below and dismisses the route. This
/// skips `Dialog` and builds the barrier itself: a full-screen
/// `GestureDetector` that pops on tap, with an inner one that swallows
/// taps landing on the card so they don't bubble up and close it.
Future<T?> showFloatingDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    // Real dismiss-on-tap is handled by our own GestureDetector below,
    // which sits on top of and fully covers the built-in barrier.
    barrierDismissible: true,
    builder: (context) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {}, // swallow taps on the card itself
          child: Builder(builder: builder),
        ),
      ),
    ),
  );
}
