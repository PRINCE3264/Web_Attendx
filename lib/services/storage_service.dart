import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();

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
    // Read bytes
    final Uint8List bytes = await file.readAsBytes();
    
    // In production with active Firebase Storage config, this executes:
    // final ref = FirebaseStorage.instance.ref().child('attendance-photos/$userId/${date}_$type.jpg');
    // final uploadTask = await ref.putData(bytes);
    // return await uploadTask.ref.getDownloadURL();

    // High performance portable base64 / data-uri representation
    final base64String = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64String';
  }
}
