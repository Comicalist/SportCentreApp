import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// Secure image upload service with validation and Firebase Storage integration
/// Handles facility and activity images with format validation, size limits, and automatic optimization
class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Image constraints for optimal performance and security
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB limit for reasonable upload times
  static const int maxWidthPixels = 1200; // Balance quality vs loading speed
  static const int maxHeightPixels = 900;
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];

  /// Comprehensive image validation to prevent malicious uploads and ensure quality
  static Future<String?> _validateImage(XFile imageFile) async {
    try {
      /// File extension validation for basic security filtering
      final extension = path
          .extension(imageFile.path)
          .toLowerCase()
          .replaceAll('.', '');
      if (!allowedExtensions.contains(extension)) {
        return 'Invalid file format. Please use JPG, PNG, or WebP images only.';
      }

      /// File size validation to prevent storage abuse and slow uploads
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSizeBytes) {
        final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        return 'File too large (${sizeMB}MB). Maximum size is 5MB.';
      }

      /// MIME type validation for additional security layer
      if (imageFile.mimeType != null &&
          !allowedMimeTypes.contains(imageFile.mimeType!.toLowerCase())) {
        return 'Invalid file type detected. Please use a valid image file.';
      }

      /// File content validation to ensure legitimate image data
      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        return 'Invalid image file. Please select a different image.';
      }

      /// Binary header validation to prevent disguised malicious files
      if (!_isValidImageHeader(bytes)) {
        return 'Invalid image format. Please select a valid image file.';
      }

      return null;
    } catch (e) {
      return 'Error validating image: Please try again with a different image.';
    }
  }

  /// Binary header validation to verify authentic image file formats
  /// Prevents upload of non-image files with spoofed extensions
  static bool _isValidImageHeader(Uint8List bytes) {
    if (bytes.length < 4) return false;

    /// JPEG signature: FF D8 FF (Start of Image marker)
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    /// PNG signature: 89 50 4E 47 (PNG file header)
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    /// WebP signature: RIFF container with WEBP identifier
    if (bytes.length >= 12) {
      final riff = String.fromCharCodes(bytes.sublist(0, 4));
      final webp = String.fromCharCodes(bytes.sublist(8, 12));
      if (riff == 'RIFF' && webp == 'WEBP') {
        return true;
      }
    }

    return false;
  }

  /// Complete image upload workflow with user guidance and automatic optimization
  /// Supports both facility and activity image management
  static Future<String?> pickAndUploadImage({
    required String type, // 'activities' or 'facilities' for organized storage
    required String id,
    required BuildContext context,
  }) async {
    try {
      /// User-friendly source selection with upload requirements
      final source = await _showImageSourceDialog(context);
      if (source == null) return null;

      /// Image capture with automatic optimization for web display
      final image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidthPixels.toDouble(),
        maxHeight: maxHeightPixels.toDouble(),
        imageQuality: 85, // Optimal balance between quality and file size
      );

      if (image == null) return null;

      /// Security and quality validation before upload
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

      /// Unique filename generation to prevent conflicts and enable caching
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(image.path);
      final fileName = '${timestamp}_$id$extension';

      /// Organized storage structure for efficient management
      final ref = _storage.ref().child('$type/$id/$fileName');

      /// Upload with progress tracking for user feedback
      final uploadTask = ref.putFile(File(image.path));

      /// Retrieve download URL for database storage and display
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

  /// User-friendly source selection dialog with clear upload requirements
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
              /// Clear requirements display to prevent upload failures
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

              /// Source selection options for flexible image capture
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

  /// Safe image deletion with error tolerance for cleanup operations
  static Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      /// Silent failure acceptable - image might already be deleted or URL invalid
    }
  }

  /// Formatted requirements text for user guidance and support documentation
  static String getValidationRequirements() {
    return '• Format: ${allowedExtensions.join(', ').toUpperCase()}\n'
        '• Max size: ${(maxFileSizeBytes / (1024 * 1024)).toInt()}MB\n'
        '• Max dimensions: ${maxWidthPixels}x${maxHeightPixels}px\n'
        '• Landscape orientation recommended';
  }
}
