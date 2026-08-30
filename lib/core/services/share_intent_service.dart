import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Something shared into Mimo from another app — a product link/text, or
/// a photo. Normalized from the platform plugin's [SharedMediaFile] so
/// the rest of the app doesn't need to know about its `path`/`type` shape
/// (for a text/url share, `path` *is* the shared string; for an image
/// share on Android, it's a real file path the plugin already resolved
/// from the `content://` uri).
sealed class SharedCapture {
  const SharedCapture();
}

class SharedCaptureUrl extends SharedCapture {
  const SharedCaptureUrl(this.text);
  final String text;
}

class SharedCaptureImage extends SharedCapture {
  const SharedCaptureImage(this.bytes);
  final Uint8List bytes;
}

/// Thin wrapper around `receive_sharing_intent`. Android only — Mimo has
/// no Windows share-target mechanism, and the plugin has no Windows
/// implementation to call into (no native handler is registered there,
/// so calling it would throw); every method here is a safe no-op off
/// Android instead of guarding at every call site.
class ShareIntentService {
  bool get _supported => Platform.isAndroid;

  /// The share that launched the app (cold start), if any. Always resets
  /// the plugin's stored intent after reading it, so the same share isn't
  /// redelivered on the next launch.
  Future<SharedCapture?> consumeInitial() async {
    if (!_supported) return null;
    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    await ReceiveSharingIntent.instance.reset();
    return _firstCapture(files);
  }

  /// Shares received while the app is already running.
  Stream<SharedCapture> get stream {
    if (!_supported) return const Stream.empty();
    return ReceiveSharingIntent.instance
        .getMediaStream()
        .asyncMap(_firstCapture)
        .where((c) => c != null)
        .cast<SharedCapture>();
  }

  Future<SharedCapture?> _firstCapture(List<SharedMediaFile> files) async {
    if (files.isEmpty) return null;
    final file = files.first;
    switch (file.type) {
      case SharedMediaType.text:
      case SharedMediaType.url:
        return SharedCaptureUrl(file.path);
      case SharedMediaType.image:
        try {
          return SharedCaptureImage(await File(file.path).readAsBytes());
        } catch (_) {
          return null;
        }
      case SharedMediaType.video:
      case SharedMediaType.file:
        return null;
    }
  }
}
