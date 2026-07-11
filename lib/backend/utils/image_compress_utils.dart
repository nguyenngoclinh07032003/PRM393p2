import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageCompressUtils {
  ImageCompressUtils._();

  static const int _webTargetWidth = 1024;
  static const int _mobileMaxDimension = 1280;

  static Future<Uint8List> compressForUpload(
    Uint8List bytes, {
    int maxDimension = _mobileMaxDimension,
    int quality = 80,
  }) async {
    if (bytes.isEmpty) return bytes;

    if (kIsWeb) {
      return _compressOnWeb(bytes, quality: quality);
    }

    return compute(
      _compressForUpload,
      _CompressRequest(
        bytes: bytes,
        maxDimension: maxDimension,
        quality: quality,
      ),
    );
  }

  static Future<Uint8List> _compressOnWeb(
    Uint8List bytes, {
    required int quality,
  }) async {
    try {
      await Future<void>.delayed(Duration.zero);

      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: _webTargetWidth,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();

      if (rgba == null || width <= 0 || height <= 0) {
        return bytes;
      }

      final bitmap = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: rgba.buffer,
        numChannels: 4,
      );

      return Uint8List.fromList(img.encodeJpg(bitmap, quality: quality));
    } catch (e) {
      debugPrint('Web image compress error: $e');
      return bytes;
    }
  }
}

class _CompressRequest {
  const _CompressRequest({
    required this.bytes,
    required this.maxDimension,
    required this.quality,
  });

  final Uint8List bytes;
  final int maxDimension;
  final int quality;
}

Uint8List _compressForUpload(_CompressRequest request) {
  try {
    final decoded = img.decodeImage(request.bytes);
    if (decoded == null) return request.bytes;

    final maxSide = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;

    final resized = maxSide > request.maxDimension
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height
                ? request.maxDimension
                : null,
            height: decoded.height > decoded.width
                ? request.maxDimension
                : null,
          )
        : decoded;

    return Uint8List.fromList(
      img.encodeJpg(resized, quality: request.quality),
    );
  } catch (_) {
    return request.bytes;
  }
}
