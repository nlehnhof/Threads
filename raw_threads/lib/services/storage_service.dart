import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageHelper {
  /// Picks an image from gallery or camera and uploads it to Firebase Storage.
  /// Returns the download URL of the uploaded image.
  static Future<String?> pickAndUploadImage({
    required String storagePath, // e.g., "admins/$adminId/costumes"
    bool fromCamera = false,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1080, // optional resizing
        maxHeight: 1080,
      );

      if (pickedFile == null) return null; // user canceled

      final file = File(pickedFile.path);

      final storageRef = FirebaseStorage.instance.ref();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final uploadRef = storageRef.child('$storagePath/$fileName');

      final uploadTask = await uploadRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Image upload failed: $e');
      return null;
    }
  }

  /// Directly uploads an existing File to Firebase Storage
  /// Returns the download URL
  static Future<String> uploadFile({
    required String storagePath, // e.g., "admins/$adminId/costumes"
    required File file,
  }) async {
    final storageRef = FirebaseStorage.instance.ref();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final uploadRef = storageRef.child('$storagePath/$fileName');

    await uploadRef.putFile(file);
    return await uploadRef.getDownloadURL();
  }
}
