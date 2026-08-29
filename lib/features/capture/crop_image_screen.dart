import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';

/// Locked to 1:1 — the blueprint's "recorte automático (crop 1x1) do
/// produto identificado" rule. This is the manual stand-in for that until
/// there's a real vision model suggesting the crop; the aspect ratio rule
/// itself already holds today.
class CropImageScreen extends StatefulWidget {
  const CropImageScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

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
        title: const Text('Recortar capa'),
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
        withCircleUi: false,
        baseColor: Colors.black,
        maskColor: Colors.black.withValues(alpha: 0.65),
        onCropped: _onCropped,
      ),
    );
  }
}
