import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageHelper {
  static final _picker = ImagePicker();
  static final _storage = FirebaseStorage.instance;
  static final _uuid = Uuid();

  /// Safely encode IDs for Firebase Storage paths
  static String safePath(String id) => id.replaceAll(RegExp(r'[^\w\-]'), '_');

  /// Pick a file from gallery or camera
  static Future<File?> pickFile({bool fromCamera = false}) async {
    try {
      print('Picking file from ${fromCamera ? "camera" : "gallery"}...');
      final picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (picked == null) {
        print('No file picked.');
        return null;
      }
      print('File picked: ${picked.path}');
      return File(picked.path);
    } catch (e, st) {
      print('Error picking file: $e\n$st');
      return null;
    }
  }

  /// Upload a file to Firebase Storage and return the download URL
  static Future<String?> uploadFile({
    required File file,
    required String storagePath,
  }) async {
    try {
      final safeStoragePath = storagePath
          .split('/')
          .map((segment) => safePath(segment))
          .join('/');
      final fileName = '${_uuid.v4()}.jpg';
      final fullPath = '$safeStoragePath/$fileName';

      print('Uploading file to path: $fullPath');

      final ref = _storage.ref().child(fullPath);

      // Create an UploadTask
      final UploadTask task = ref.putFile(file);

      // Listen to task events for debugging
      task.snapshotEvents.listen((event) {
        print(
            'Upload state: ${event.state}, bytes transferred: ${event.bytesTransferred}/${event.totalBytes}');
      });

      // Await completion
      await task;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      print('Upload complete. Download URL: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      print(
          'FirebaseException during upload.\nCode: ${e.code}\nMessage: ${e.message}\nDetails: ${e.stackTrace}');
      return null;
    } catch (e, st) {
      print('Error uploading file: $e\n$st');
      return null;
    }
  }


  /// Pick an image and upload it immediately, returning the Firebase download URL
  static Future<String?> pickUploadAndReturnUrl({
    required String storagePath,
    bool fromCamera = false,
  }) async {
    try {
      final pickedFile = await pickFile(fromCamera: fromCamera);
      if (pickedFile == null) {
        print('pickUploadAndReturnUrl: No file selected.');
        return null;
      }

      print('Starting upload...');
      final downloadUrl = await uploadFile(
        file: pickedFile,
        storagePath: storagePath,
      );

      if (downloadUrl == null) {
        print('pickUploadAndReturnUrl: Upload returned null.');
      } else {
        print('pickUploadAndReturnUrl: Upload successful. URL: $downloadUrl');
      }

      return downloadUrl;
    } catch (e, st) {
      print('pickUploadAndReturnUrl error: $e\n$st');
      return null;
    }
  }
}
