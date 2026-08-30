import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/mimo_colors.dart';

/// Shows the camera-or-gallery bottom sheet, then reads the picked
/// image's bytes — the same "which source, then read it" flow the cover
/// and avatar pickers both need. Returns null if the user backs out at
/// either step.
Future<Uint8List?> pickImageBytes(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _ImageSourceSheet(colors: MimoColors.of(context)),
  );
  if (source == null) return null;

  final picked = await ImagePicker().pickImage(source: source, imageQuality: 90);
  if (picked == null) return null;

  return picked.readAsBytes();
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet({required this.colors});

  final MimoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: colors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (Platform.isAndroid || Platform.isIOS)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Câmera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Galeria'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
