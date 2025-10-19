import 'package:flutter/material.dart';
import '../../models/facility.dart';
import '../../models/club.dart';
import '../../services/facility_service.dart';

class AddFacilityScreen extends StatefulWidget {
  final Club club;

  const AddFacilityScreen({super.key, required this.club});

  @override
  State<AddFacilityScreen> createState() => _AddFacilityScreenState();
}

class _AddFacilityScreenState extends State<AddFacilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;

  final FacilityService _facilityService = FacilityService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _imageUrlController.dispose();
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
                    _buildImagePreview(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildClubInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal,
              child: const Icon(Icons.business, color: Colors.white),
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

            // Image URL (Optional)
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (Optional)',
                hintText: 'https://example.com/facility-image.jpg',
                border: OutlineInputBorder(),
                helperText:
                    'Leave empty to use a default image based on facility type',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasScheme) {
                    return 'Please enter a valid URL';
                  }
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

  Widget _buildImagePreview() {
    final imageUrl = _imageUrlController.text.trim();
    final previewUrl = imageUrl.isNotEmpty
        ? imageUrl
        : _getDefaultImagePreview();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.preview, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Image Preview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(previewUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: imageUrl.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: const Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          'Default Image',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

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

  Future<void> _submitFacility() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate club is approved
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
        id: '', // Will be set by Firestore
        clubId: widget.club.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        maxCapacity: int.parse(_capacityController.text.trim()),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
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
