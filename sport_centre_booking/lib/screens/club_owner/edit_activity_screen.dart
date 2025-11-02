import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/activity.dart';
import '../../models/facility.dart';
import '../../services/activity_service.dart';
import '../../services/facility_service.dart';
import '../../services/imageUpload_service.dart';

class EditActivityScreen extends StatefulWidget {
  const EditActivityScreen({super.key, required this.activity});
  final Activity activity;

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _facilityService = FacilityService();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _guestPriceController = TextEditingController();
  final _memberPriceController = TextEditingController();
  final _capacityController = TextEditingController();
  final _pointsController = TextEditingController();
  final _durationController = TextEditingController();

  // Form state
  List<Facility> _facilities = [];
  Facility? _selectedFacility;
  String _selectedCategory = 'Wellness';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final List<String> _requirements = [];
  bool _isLoading = false;

  String? _newImageUrl; // For tracking new uploaded image
  bool _isUploadingImage = false;

  final List<String> _categories = ['Wellness', 'Fitness', 'Kids', 'Workshops'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadFacilities();
  }

  void _initializeForm() {
    final activity = widget.activity;

    _nameController.text = activity.name;
    _descriptionController.text = activity.description;
    _guestPriceController.text = activity.guestPrice.toString();
    _memberPriceController.text = activity.memberPrice.toString();
    _capacityController.text = activity.capacity.toString();
    _pointsController.text = activity.pointsReward.toString();
    _durationController.text = activity.duration.toString();

    _selectedCategory = activity.category;
    _selectedDate = activity.date;
    _requirements.addAll(activity.requirements);

    // Parse time

    final timeParts = activity.time.split(':');
    if (timeParts.length == 2) {
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _guestPriceController.dispose();
    _memberPriceController.dispose();
    _capacityController.dispose();
    _pointsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadFacilities() async {
    try {
      final facilities = await _facilityService.getClubFacilities(
        clubId: widget.activity.clubId,
      );
      final activeFacilities = facilities.where((f) => f.isActive).toList();

      setState(() {
        _facilities = activeFacilities;
        // Find current facility
        _selectedFacility = activeFacilities.firstWhere(
          (f) => f.id == widget.activity.facilityId,
          orElse: () => activeFacilities.isNotEmpty
              ? activeFacilities.first
              : throw Exception('No facilities available'),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading facilities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    // Don't allow editing past activities
    if (widget.activity.isPast) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit past activities'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Widget _buildImageSection() {
    final currentImageUrl = _newImageUrl ?? widget.activity.displayImageUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Activity Image'),
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
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 16,
                    ),
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

  Future<void> _uploadNewImage() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await ImageUploadService.pickAndUploadImage(
        type: 'activities',
        id: widget.activity.id,
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

  Future<void> _updateActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFacility == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a facility'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate capacity
      final newCapacity = int.parse(_capacityController.text);
      if (newCapacity < widget.activity.bookedCount) {
        throw Exception(
          'Capacity cannot be less than current bookings (${widget.activity.bookedCount})',
        );
      }

      if (newCapacity > _selectedFacility!.maxCapacity) {
        throw Exception(
          'Capacity ($newCapacity) exceeds facility maximum (${_selectedFacility!.maxCapacity})',
        );
      }

      // Create time string
      final timeString =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      final duration = int.parse(_durationController.text);

      // Create updated activity
      final updatedActivity = widget.activity.copyWith(
        facilityId: _selectedFacility!.id,
        facilityName: _selectedFacility!.title,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        date: _selectedDate,
        time: timeString,
        duration: duration,
        timeCategory: Activity.getTimeCategory(timeString),
        capacity: newCapacity,
        guestPrice: double.parse(_guestPriceController.text),
        memberPrice: double.parse(_memberPriceController.text),
        pointsReward: int.parse(_pointsController.text),
        requirements: _requirements,
        imageUrl: _newImageUrl ?? widget.activity.imageUrl,
        updatedAt: DateTime.now(),
      );

      // ✅ Fix: Pass the required currentUserId parameter
      await ActivityService.updateActivity(
        activity: updatedActivity,
        currentUserId: user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating activity: $e'),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Edit: ${widget.activity.name}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (widget.activity.isPast)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'PAST',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning for past activities
              if (widget.activity.isPast) ...[
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This activity is in the past. Limited editing is available.',
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Current bookings info
              if (widget.activity.bookedCount > 0) ...[
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.blue[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Current bookings: ${widget.activity.bookedCount}/${widget.activity.capacity}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Basic Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Basic Information'),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Activity Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? false ? 'Required' : null,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            value?.isEmpty ?? false ? 'Required' : null,
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCategory = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Facility Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Facility'),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<Facility>(
                        initialValue: _selectedFacility,
                        decoration: const InputDecoration(
                          labelText: 'Select Facility *',
                          border: OutlineInputBorder(),
                        ),
                        items: _facilities.map((facility) {
                          return DropdownMenuItem(
                            value: facility,
                            child: Text(
                              '${facility.title} (Max: ${facility.maxCapacity})',
                            ),
                          );
                        }).toList(),
                        onChanged: (facility) {
                          setState(() => _selectedFacility = facility);
                        },
                        validator: (value) =>
                            value == null ? 'Please select a facility' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Date & Time
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Schedule'),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date *',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(_selectedDate),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _selectTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Time *',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(_selectedTime.format(context)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes) *',
                          border: OutlineInputBorder(),
                          suffixText: 'minutes',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? false) return 'Required';
                          final duration = int.tryParse(value!);
                          if (duration == null || duration <= 0)
                            return 'Enter valid duration';
                          if (duration > 480)
                            return 'Duration cannot exceed 8 hours';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Capacity & Pricing
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Capacity & Pricing'),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _capacityController,
                        decoration: InputDecoration(
                          labelText: 'Capacity *',
                          border: const OutlineInputBorder(),
                          helperText: widget.activity.bookedCount > 0
                              ? 'Minimum: ${widget.activity.bookedCount} (current bookings)'
                              : null,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? false) return 'Required';
                          final capacity = int.tryParse(value!);
                          if (capacity == null || capacity <= 0)
                            return 'Enter valid capacity';
                          if (capacity < widget.activity.bookedCount) {
                            return 'Cannot be less than current bookings (${widget.activity.bookedCount})';
                          }
                          if (_selectedFacility != null &&
                              capacity > _selectedFacility!.maxCapacity) {
                            return 'Exceeds facility maximum (${_selectedFacility!.maxCapacity})';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _guestPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Guest Price *',
                                border: OutlineInputBorder(),
                                prefixText: r'$',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? false) return 'Required';
                                final price = double.tryParse(value!);
                                if (price == null || price < 0)
                                  return 'Enter valid price';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _memberPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Member Price *',
                                border: OutlineInputBorder(),
                                prefixText: r'$',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? false) return 'Required';
                                final price = double.tryParse(value!);
                                if (price == null || price < 0)
                                  return 'Enter valid price';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _pointsController,
                        decoration: const InputDecoration(
                          labelText: 'Points Reward *',
                          border: OutlineInputBorder(),
                          suffixText: 'points',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? false) return 'Required';
                          final points = int.tryParse(value!);
                          if (points == null || points < 0)
                            return 'Enter valid points';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Image Section
              _buildImageSection(),

              const SizedBox(height: 32),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Activity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
