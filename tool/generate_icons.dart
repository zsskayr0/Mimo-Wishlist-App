// Regenerates assets/icon/*.png from the official brand SVGs
// (C:\Users\roque\Downloads\Mimo app logo design\svg\mimo-icon.svg /
// mimo-app-icon-512.svg). Draws the mark directly with dart:ui's
// Canvas/Path — deliberately avoids flutter_svg here: its picture
// decoding hangs under flutter_test's fake clock (pumpAndSettle never
// settles, and fixed pumps time out too), while raw Canvas painting is
// fully synchronous and has none of that risk. Run with:
//   flutter test tool/generate_icons.dart
// then `dart run flutter_launcher_icons` to apply the results.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

// Mark path, transcribed 1:1 from the SVG:
// M34.5 6H50a8 8 0 0 1 8 8v15.5a8 8 0 0 1-2.34 5.66L34.16 56.66
// a8 8 0 0 1-11.31 0L7.34 41.15a8 8 0 0 1 0-11.31L28.84 8.34
// A8 8 0 0 1 34.5 6Z
// All arcs are r=8, rotation 0, large-arc-flag 0, sweep-flag 1 — SVG's
// sweep-flag=1 maps to Path.arcToPoint's clockwise: true (default).
ui.Path _markPath() {
  return ui.Path()
    ..moveTo(34.5, 6)
    ..lineTo(50, 6)
    ..arcToPoint(const ui.Offset(58, 14), radius: const ui.Radius.circular(8))
    ..lineTo(58, 29.5)
    ..arcToPoint(const ui.Offset(55.66, 35.16), radius: const ui.Radius.circular(8))
    ..lineTo(34.16, 56.66)
    ..arcToPoint(const ui.Offset(22.85, 56.66), radius: const ui.Radius.circular(8))
    ..lineTo(7.34, 41.15)
    ..arcToPoint(const ui.Offset(7.34, 29.84), radius: const ui.Radius.circular(8))
    ..lineTo(28.84, 8.34)
    ..arcToPoint(const ui.Offset(34.5, 6), radius: const ui.Radius.circular(8))
    ..close();
}

ui.Path _holeCircle() {
  return ui.Path()..addOval(ui.Rect.fromCircle(center: const ui.Offset(45, 19), radius: 5.2));
}

ui.Shader _brandGradient() {
  return ui.Gradient.linear(
    const ui.Offset(6, 6),
    const ui.Offset(58, 58),
    const [ui.Color(0xFFFFB199), ui.Color(0xFFE0619A), ui.Color(0xFF8A4FFF)],
    const [0.0, 0.5, 1.0],
  );
}

Future<void> _writePng(ui.Picture picture, int size, String outPath) async {
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(outPath);
  file.parent.createSync(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('Wrote $outPath (${bytes.lengthInBytes} bytes)');
}

/// Full flattened icon — gradient square + white mark + rosé hole. Used
/// as the base/legacy Android icon and the Windows .ico source (neither
/// platform has an adaptive-icon concept, so this is the whole tile).
Future<void> _flattened(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.scale(size / 64);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 64, 64), ui.Paint()..shader = _brandGradient());
  // The official app-icon SVG draws the mark edge-to-edge in its 64-unit
  // box; on a real device (plus Android's own further masking/rounding on
  // top) that reads as too tightly cropped. Scale it down and recenter
  // for more breathing room — background stays full-bleed.
  canvas.translate(32, 32);
  canvas.scale(0.8);
  canvas.translate(-32, -32);
  canvas.drawPath(_markPath(), ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  canvas.drawPath(_holeCircle(), ui.Paint()..color = const ui.Color(0xFFE0619A));
  await _writePng(recorder.endRecording(), size, 'assets/icon/app_icon.png');
}

/// Adaptive background layer — just the gradient, full bleed.
Future<void> _background(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.scale(size / 64);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 64, 64), ui.Paint()..shader = _brandGradient());
  await _writePng(recorder.endRecording(), size, 'assets/icon/app_icon_background.png');
}

/// Adaptive foreground layer — transparent canvas, mark at its natural
/// (unshrunk) proportions, same as the flattened icon. flutter_launcher_
/// icons' generated adaptive-icon XML already applies its own 16% inset
/// on this layer (Android's official ~61-66% safe-zone recommendation),
/// so no extra manual shrink is applied here — doing both would pad the
/// glyph twice and leave it looking too small on the home screen. The
/// hole is a real cutout (Path difference), not a solid fill, so the
/// composited background gradient shows through it.
Future<void> _foreground(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.scale(size / 64);
  final glyph = ui.Path.combine(ui.PathOperation.difference, _markPath(), _holeCircle());
  canvas.drawPath(glyph, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  await _writePng(recorder.endRecording(), size, 'assets/icon/app_icon_foreground.png');
}

void main() {
  testWidgets(
    'generate icons',
    (tester) async {
      // Picture.toImage() is backed by the real raster thread, not the
      // FakeAsync zone testWidgets runs in by default — runAsync() steps
      // outside that zone so the real callback can actually fire.
      await tester.runAsync(() async {
        await _flattened(1024);
        await _background(1024);
        await _foreground(1024);
      });
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
