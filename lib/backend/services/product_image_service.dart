import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../config/app_constants.dart';
import '../utils/image_compress_utils.dart';

class ProductImageService {
  ProductImageService({
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  static const _maxUploadBytes = 12 * 1024 * 1024;
  static const _uploadTimeout = Duration(seconds: 90);

  final FirebaseStorage _storage;
  final ImagePicker _picker;
  final _uuid = const Uuid();

  Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: kIsWeb ? 75 : 85,
        maxWidth: kIsWeb ? 1024 : 1600,
        requestFullMetadata: false,
      );
    } catch (e) {
      debugPrint('Pick image error: $e');
      rethrow;
    }
  }

  Future<String> uploadImage({
    required XFile file,
    required String userId,
    void Function(String message)? onStageChanged,
  }) async {
    onStageChanged?.call('Đang đọc ảnh...');
    await Future<void>.delayed(Duration.zero);

    final length = await file.length();
    if (length > _maxUploadBytes) {
      throw Exception('Ảnh quá lớn. Vui lòng chọn ảnh dưới 12MB.');
    }

    final rawBytes = await file.readAsBytes();

    onStageChanged?.call('Đang nén ảnh...');
    await Future<void>.delayed(Duration.zero);

    final bytes = await ImageCompressUtils.compressForUpload(rawBytes);

    onStageChanged?.call('Đang tải ảnh lên...');

    final fileName = '${_uuid.v4()}.jpg';
    final path =
        '${AppConstants.productImagesStoragePath}/$userId/$fileName';

    final ref = _storage.ref().child(path);
    await ref
        .putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        )
        .timeout(_uploadTimeout);

    return ref.getDownloadURL().timeout(_uploadTimeout);
  }
}
