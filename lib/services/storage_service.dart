import 'dart:async';
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

  Future<XFile?> captureSelfiePhoto({ImageSource source = ImageSource.camera}) async {
    try {
      if (source == ImageSource.gallery) {
        return await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
      }

      // Try front camera first
      try {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        return photo;
      } catch (frontErr) {
        debugPrint('Front camera pick notice, falling back to default camera: $frontErr');
        return await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
      }
    } catch (e) {
      debugPrint('Camera pick error: $e');
      return null;
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
      final task = ref.putData(bytes, metadata);
      await task.timeout(const Duration(seconds: 4), onTimeout: () {
        task.cancel();
        throw TimeoutException('Firebase Storage upload timed out after 4s');
      });
      final downloadUrl = await ref.getDownloadURL().timeout(const Duration(seconds: 3));
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
      final task = ref.putData(bytes, metadata);
      await task.timeout(const Duration(seconds: 4), onTimeout: () {
        task.cancel();
        throw TimeoutException('Firebase Storage profile upload timed out');
      });
      final downloadUrl = await ref.getDownloadURL().timeout(const Duration(seconds: 3));
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage profile upload fallback: $e');
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    }
  }

  Future<String> uploadProjectReportMedia({
    required String reportId,
    required String userId,
    required String fileName,
    required XFile file,
  }) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final extension = fileName.split('.').last.toLowerCase();
      final contentType = extension == 'mp4' ? 'video/mp4' : 'image/jpeg';

      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('project_reports/$userId/$reportId/$fileName');
        final metadata = SettableMetadata(contentType: contentType);
        final task = ref.putData(bytes, metadata);
        await task.timeout(const Duration(seconds: 6), onTimeout: () {
          task.cancel();
          throw TimeoutException('Firebase Storage upload timed out after 6s');
        });
        final downloadUrl = await ref.getDownloadURL().timeout(const Duration(seconds: 3));
        return downloadUrl;
      } catch (e) {
        debugPrint('Firebase Storage report media upload fallback: $e');
        if (contentType.startsWith('video') || bytes.length > 200000) {
          return file.path;
        }
        final base64String = base64Encode(bytes);
        return 'data:$contentType;base64,$base64String';
      }
    } catch (e) {
      debugPrint('Media read error: $e');
      return file.path;
    }
  }
}

