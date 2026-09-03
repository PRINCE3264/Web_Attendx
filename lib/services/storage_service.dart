import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickPhotoFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return photo;
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      return null;
    }
  }

  Future<XFile?> pickPhotoFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return photo;
    } catch (e) {
      debugPrint('Camera pick error: $e');
      return null;
    }
  }

  Future<XFile?> captureSelfiePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return photo;
    } catch (e) {
      // Fallback for desktop or environments without camera access
      try {
        final XFile? galleryPhoto = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        return galleryPhoto;
      } catch (err) {
        return null;
      }
    }
  }

  Future<String> uploadAttendancePhoto({
    required String userId,
    required String date,
    required String type, // 'clockIn' or 'clockOut'
    required XFile file,
  }) async {
    final Uint8List bytes = await file.readAsBytes();

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('attendance_photos/$userId/${date}_$type.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage upload fallback: $e');
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    }
  }

  Future<String> uploadProfilePhoto({
    required String userId,
    required XFile file,
  }) async {
    final Uint8List bytes = await file.readAsBytes();

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos/$userId.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage profile upload fallback: $e');
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    }
  }
}

