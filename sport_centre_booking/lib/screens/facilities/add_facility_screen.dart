import 'package:flutter/material.dart';

import '../../models/club.dart';
import '../../models/facility.dart';
import '../../services/facility_service.dart';
import '../../services/image_upload_service.dart';

/// Facility creation interface for approved clubs
/// Handles facility registration with custom image upload and capacity management
class AddFacilityScreen extends StatefulWidget {
  const AddFacilityScreen({super.key, required this.club});
  final Club club;

  @override
  State<AddFacilityScreen> createState() => _AddFacilityScreenState();
}

class _AddFacilityScreenState extends State<AddFacilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;

  // Custom image management for facility branding
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  final FacilityService _facilityService = FacilityService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Add Facility'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClubInfoCard(),
                    const SizedBox(height: 24),
                    _buildFacilityForm(),
                    const SizedBox(height: 24),
                    _buildImageSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Display parent club information for context
  Widget _buildClubInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(Icons.business, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adding facility to',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    widget.club.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.club.location != null &&
                      widget.club.location!.isNotEmpty)
                    Text(
                      widget.club.location!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Core facility information form with validation
  Widget _buildFacilityForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Facility Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Facility identification and branding
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Facility Name *',
                hintText: 'e.g., Main Gym, Pool Area, Tennis Court',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a facility name';
                }
                if (value.trim().length < 3) {
                  return 'Facility name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Marketing and user information
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText:
                    'Describe the facility, equipment, and available activities...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Booking capacity management
            TextFormField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximum Capacity *',
                hintText: 'Number of people',
                border: OutlineInputBorder(),
                suffixText: 'people',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter maximum capacity';
                }
                final capacity = int.tryParse(value.trim());
                if (capacity == null || capacity <= 0) {
                  return 'Please enter a valid number greater than 0';
                }
                if (capacity > 500) {
                  return 'Maximum capacity cannot exceed 500';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Operational availability control
            SwitchListTile(
              title: const Text('Active Status'),
              subtitle: const Text('Facility is available for bookings'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  /// Custom image upload with fallback to type-based defaults
  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Facility Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Technical requirements for image uploads
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Image requirements: Max 5MB, JPG/PNG/WebP format, Max 1200x800px. If no image is uploaded, a default image will be used.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Image preview with custom or default display
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _uploadedImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _uploadedImageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.teal,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(_getDefaultImagePreview()),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: const Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'Default Image (Will be used if no custom image is uploaded)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 12),

            // Image management controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _uploadImage,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload),
                    label: Text(
                      _isUploadingImage
                          ? 'Uploading...'
                          : 'Upload Custom Image',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (_uploadedImageUrl != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handle custom image upload with progress feedback
  Future<void> _uploadImage() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Generate unique identifier for storage path
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();

      final imageUrl = await ImageUploadService.pickAndUploadImage(
        type: 'facilities',
        id: tempId,
        context: context,
      );

      if (imageUrl != null) {
        setState(() {
          _uploadedImageUrl = imageUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  /// Remove custom image and revert to default
  void _removeImage() {
    if (_uploadedImageUrl != null) {
      // Clean up storage to prevent orphaned files
      ImageUploadService.deleteImage(_uploadedImageUrl!);
      setState(() {
        _uploadedImageUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image removed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Select appropriate default image based on facility type
  String _getDefaultImagePreview() {
    final title = _titleController.text.toLowerCase();
    if (title.contains('gym') || title.contains('weight')) {
      return Facility.defaultImages['gym']!;
    } else if (title.contains('pool') || title.contains('swim')) {
      return Facility.defaultImages['pool']!;
    } else if (title.contains('court') ||
        title.contains('tennis') ||
        title.contains('basketball') ||
        title.contains('badminton')) {
      return Facility.defaultImages['court']!;
    } else if (title.contains('studio') ||
        title.contains('yoga') ||
        title.contains('dance') ||
        title.contains('class')) {
      return Facility.defaultImages['studio']!;
    }
    return Facility.defaultImages['default']!;
  }

  /// Submit button with loading state
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitFacility,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Add Facility',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  /// Create facility with approval requirement validation
  Future<void> _submitFacility() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Enforce club approval requirement for facility creation
    if (!widget.club.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add facilities to unapproved clubs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final facility = Facility(
        id: '', // Firestore will generate unique identifier
        clubId: widget.club.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        maxCapacity: int.parse(_capacityController.text.trim()),
        imageUrl: _uploadedImageUrl, // Custom image or null for default
        isActive: _isActive,
        createdAt: now,
        updatedAt: now,
      );

      await _facilityService.addFacility(facility: facility);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${facility.title} added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding facility: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
