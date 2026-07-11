import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../config/app_constants.dart';

class ProductImageService {
  ProductImageService({
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  final FirebaseStorage _storage;
  final ImagePicker _picker;
  final _uuid = const Uuid();

  Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } catch (e) {
      debugPrint('Pick image error: $e');
      rethrow;
    }
  }

  Future<String> uploadImage({
    required XFile file,
    required String userId,
  }) async {
    final bytes = await file.readAsBytes();
    final extension = _fileExtension(file.name);
    final fileName = '${_uuid.v4()}.$extension';
    final path =
        '${AppConstants.productImagesStoragePath}/$userId/$fileName';

    final ref = _storage.ref().child(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: _contentType(extension)),
    );
    return ref.getDownloadURL();
  }

  String _fileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) return 'jpg';
    final ext = parts.last.toLowerCase();
    if (ext == 'jpeg') return 'jpg';
    return ext;
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}
