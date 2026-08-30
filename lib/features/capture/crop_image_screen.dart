import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';

/// A 1:1 crop screen. No longer used for mimo covers (those keep their
/// original aspect ratio — see MimoCard's doc comment for why); square
/// still makes sense for a profile photo, since avatars are always shown
/// circular regardless of any view-mode setting.
class CropImageScreen extends StatefulWidget {
  const CropImageScreen({super.key, required this.imageBytes, this.title = 'Recortar imagem', this.circular = false});

  final Uint8List imageBytes;
  final String title;

  /// Shows the crop mask as a circle instead of a square — purely a
  /// preview aid for avatars; the cropped bytes are still a square image
  /// either way (the app renders avatars circular itself via ClipOval).
  final bool circular;

  @override
  State<CropImageScreen> createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  final _controller = CropController();
  bool _isCropping = false;

  void _confirm() {
    setState(() => _isCropping = true);
    _controller.crop();
  }

  void _onCropped(CropResult result) {
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(croppedImage);
      case CropFailure():
        setState(() => _isCropping = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Não deu pra recortar essa imagem.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _isCropping ? null : _confirm,
            child: Text(
              'Cortar',
              style: TextStyle(
                color: _isCropping ? Colors.white38 : MimoColors.gradientA,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Crop(
        controller: _controller,
        image: widget.imageBytes,
        aspectRatio: 1,
        withCircleUi: widget.circular,
        baseColor: Colors.black,
        maskColor: Colors.black.withValues(alpha: 0.65),
        onCropped: _onCropped,
      ),
    );
  }
}
