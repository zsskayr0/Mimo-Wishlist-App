import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads an image to a public storage bucket, under the current user's
/// own folder (`{userId}/...`) — every bucket this is used with follows
/// the same owner-scoped-path policy pattern (see 006_cover_storage.sql
/// for `mimo-covers`, 007_avatar_storage.sql for `avatars`).
class ImageUploadService {
  ImageUploadService({SupabaseClient? client, this.bucket = 'mimo-covers'})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final String bucket;

  Future<String> upload(Uint8List bytes) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('ImageUploadService.upload called with no signed-in user');
    }

    final suffix = Random().nextInt(1 << 32).toRadixString(16);
    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}_$suffix.jpg';

    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
