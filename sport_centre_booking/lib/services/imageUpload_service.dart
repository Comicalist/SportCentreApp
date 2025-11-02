import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  // Image validation constants aligned with your current implementation
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxWidthPixels = 1200;
  static const int maxHeightPixels = 900;
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];

  /// Validate image file before upload
  static Future<String?> _validateImage(XFile imageFile) async {
    try {
      // Check file extension
      final extension = path
          .extension(imageFile.path)
          .toLowerCase()
          .replaceAll('.', '');
      if (!allowedExtensions.contains(extension)) {
        return 'Invalid file format. Please use JPG, PNG, or WebP images only.';
      }

      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSizeBytes) {
        final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        return 'File too large (${sizeMB}MB). Maximum size is 5MB.';
      }

      // Check MIME type if available
      if (imageFile.mimeType != null &&
          !allowedMimeTypes.contains(imageFile.mimeType!.toLowerCase())) {
        return 'Invalid file type detected. Please use a valid image file.';
      }

      // Read image bytes to validate it's a real image
      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        return 'Invalid image file. Please select a different image.';
      }

      // Basic image header validation
      if (!_isValidImageHeader(bytes)) {
        return 'Invalid image format. Please select a valid image file.';
      }

      return null; // Validation passed
    } catch (e) {
      return 'Error validating image: Please try again with a different image.';
    }
  }

  /// Check if file has valid image header bytes
  static bool _isValidImageHeader(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // JPEG header: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    // PNG header: 89 50 4E 47
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    // WebP header: starts with "RIFF" and contains "WEBP"
    if (bytes.length >= 12) {
      final riff = String.fromCharCodes(bytes.sublist(0, 4));
      final webp = String.fromCharCodes(bytes.sublist(8, 12));
      if (riff == 'RIFF' && webp == 'WEBP') {
        return true;
      }
    }

    return false;
  }

  /// Pick and upload image with validation - following your existing pattern
  static Future<String?> pickAndUploadImage({
    required String type, // 'activities' or 'facilities'
    required String id,
    required BuildContext context,
  }) async {
    try {
      // Show image source selection with requirements
      final source = await _showImageSourceDialog(context);
      if (source == null) return null;

      // Pick image with automatic resizing (following your existing approach)
      final image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidthPixels.toDouble(),
        maxHeight: maxHeightPixels.toDouble(),
        imageQuality: 85, // Good quality while keeping file size reasonable
      );

      if (image == null) return null;

      // Validate image before upload
      final validationError = await _validateImage(image);
      if (validationError != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationError),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      // Generate unique filename following your existing pattern
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(image.path);
      final fileName = '${timestamp}_$id$extension';

      // Create storage reference
      final ref = _storage.ref().child('$type/$id/$fileName');

      // Upload with progress indication
      final uploadTask = ref.putFile(File(image.path));

      // Wait for completion and get download URL
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload image: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Show image source selection dialog with requirements
  static Future<ImageSource?> _showImageSourceDialog(
    BuildContext context,
  ) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Requirements info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Image Requirements',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      getValidationRequirements(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Source selection buttons
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Delete image from storage - following your existing pattern
  static Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Don't throw error - image might already be deleted
    }
  }

  /// Get image validation requirements as text
  static String getValidationRequirements() {
    return '• Format: ${allowedExtensions.join(', ').toUpperCase()}\n'
        '• Max size: ${(maxFileSizeBytes / (1024 * 1024)).toInt()}MB\n'
        '• Max dimensions: ${maxWidthPixels}x${maxHeightPixels}px\n'
        '• Landscape orientation recommended';
  }
}
