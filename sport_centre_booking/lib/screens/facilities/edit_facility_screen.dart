import 'package:flutter/material.dart';
import '../../models/facility.dart';
import '../../services/facility_service.dart';
import '../../services/imageUpload_service.dart'; // Add this import

class EditFacilityScreen extends StatefulWidget {
  final Facility facility;
  
  const EditFacilityScreen({
    super.key,
    required this.facility,
  });

  @override
  State<EditFacilityScreen> createState() => _EditFacilityScreenState();
}

class _EditFacilityScreenState extends State<EditFacilityScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _capacityController;
  
  late bool _isActive;
  bool _isLoading = false;
  
  // Add image upload state
  String? _newImageUrl; // For tracking new uploaded image
  bool _isUploadingImage = false;
  
  final FacilityService _facilityService = FacilityService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.facility.title);
    _descriptionController = TextEditingController(text: widget.facility.description);
    _capacityController = TextEditingController(text: widget.facility.maxCapacity.toString());
    _isActive = widget.facility.isActive;
  }

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
        title: const Text('Edit Facility'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
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
                    _buildFacilityInfoCard(),
                    const SizedBox(height: 24),
                    _buildFacilityForm(),
                    const SizedBox(height: 24),
                    _buildImageSection(), // Updated method
                    const SizedBox(height: 32),
                    _buildUpdateButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFacilityInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: const Icon(Icons.home_work, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editing facility',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        widget.facility.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.facility.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.facility.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Current capacity: ${widget.facility.maxCapacity} people',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Facility Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Facility Title
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
            
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe the facility, equipment, and available activities...',
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
            
            // Max Capacity
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
            
            // Active Status
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

  // NEW: Updated image section with upload functionality
  Widget _buildImageSection() {
    final currentImageUrl = _newImageUrl ?? widget.facility.displayImageUrl;
    
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
            const SizedBox(height: 12),
            
            // Current image preview
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  currentImageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[100],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
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
                          Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Image not available', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Upload new image button
            ElevatedButton.icon(
              onPressed: _isUploadingImage ? null : _uploadNewImage,
              icon: _isUploadingImage 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload),
              label: Text(_isUploadingImage ? 'Uploading...' : 'Change Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
            
            if (_newImageUrl != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'New image ready! Save to apply changes.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // NEW: Upload new image method
  Future<void> _uploadNewImage() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await ImageUploadService.pickAndUploadImage(
        type: 'facilities',
        id: widget.facility.id,
        context: context,
      );

      if (imageUrl != null) {
        setState(() {
          _newImageUrl = imageUrl;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New image uploaded! Save to apply changes.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  String _getDefaultImagePreview() {
    final title = _titleController.text.toLowerCase();
    if (title.contains('gym') || title.contains('weight')) {
      return Facility.defaultImages['gym']!;
    } else if (title.contains('pool') || title.contains('swim')) {
      return Facility.defaultImages['pool']!;
    } else if (title.contains('court') || title.contains('tennis') || 
               title.contains('basketball') || title.contains('badminton')) {
      return Facility.defaultImages['court']!;
    } else if (title.contains('studio') || title.contains('yoga') || 
               title.contains('dance') || title.contains('class')) {
      return Facility.defaultImages['studio']!;
    }
    return Facility.defaultImages['default']!;
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateFacility,
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
                'Update Facility',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _updateFacility() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedFacility = widget.facility.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        maxCapacity: int.parse(_capacityController.text.trim()),
        imageUrl: _newImageUrl ?? widget.facility.imageUrl, // Use new image or keep existing
        isActive: _isActive,
        updatedAt: DateTime.now(),
      );

      await _facilityService.updateFacility(facility: updatedFacility);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedFacility.title} updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating facility: $e'),
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Facility'),
        content: Text(
          'Are you sure you want to delete "${widget.facility.title}"?\n\nThis action cannot be undone and may affect existing bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFacility();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFacility() async {
    setState(() => _isLoading = true);

    try {
      await _facilityService.deleteFacility(facilityId: widget.facility.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.facility.title} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting facility: $e'),
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