import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads a cropped cover image to the `mimo-covers` bucket, under the
/// current user's own folder — see 006_cover_storage.sql for the storage
/// policies that path layout is built around.
class ImageUploadService {
  ImageUploadService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _bucket = 'mimo-covers';

  Future<String> uploadCover(Uint8List bytes) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('uploadCover called with no signed-in user');
    }

    final suffix = Random().nextInt(1 << 32).toRadixString(16);
    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}_$suffix.jpg';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
