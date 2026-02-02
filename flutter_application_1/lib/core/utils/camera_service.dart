import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service to handle camera operations and image storage
class CameraService {
  final ImagePicker _picker = ImagePicker();

  /// Take a photo using the camera
  /// Returns the path to the saved image, or null if cancelled
  Future<String?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800, // Resize to save storage
        maxHeight: 800,
        imageQuality: 85, // Compress slightly
      );

      if (photo == null) return null;

      // Save to app's documents directory
      return await _saveImageToAppStorage(photo);
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Pick an image from gallery
  /// Returns the path to the saved image, or null if cancelled
  Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _saveImageToAppStorage(image);
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Save image to app's local storage
  Future<String> _saveImageToAppStorage(XFile image) async {
    // Get the app's documents directory
    final Directory appDir = await getApplicationDocumentsDirectory();
    
    // Create a 'photos' subdirectory
    final Directory photosDir = Directory('${appDir.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    // Generate unique filename with timestamp
    final String fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
    final String savedPath = '${photosDir.path}/$fileName';

    // Copy the image to app storage
    final File newImage = await File(image.path).copy(savedPath);
    
    return newImage.path;
  }

  /// Delete a photo from storage
  Future<bool> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting photo: $e');
      return false;
    }
  }

  /// Check if a photo exists
  Future<bool> photoExists(String? photoPath) async {
    if (photoPath == null) return false;
    return await File(photoPath).exists();
  }
}
