import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/activity.dart';
import '../../models/club.dart';
import '../../models/facility.dart';
import '../../services/activity_service.dart';
import '../../services/club_service.dart';
import '../../services/facility_service.dart';
import '../../services/image_upload_service.dart';

/// Comprehensive activity creation interface for club owners with validation,
/// image management, facility capacity checks, and scheduling coordination
class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clubService = ClubService();
  final _facilityService = FacilityService();

  /// Form input controllers for activity data collection
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _guestPriceController = TextEditingController();
  final _memberPriceController = TextEditingController();
  final _capacityController = TextEditingController();
  final _pointsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _durationController = TextEditingController(text: '60');

  /// Activity configuration state management
  List<Club> _ownedClubs = [];
  List<Facility> _facilities = [];
  Club? _selectedClub;
  Facility? _selectedFacility;
  String _selectedCategory = 'Wellness';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final List<String> _requirements = [];
  bool _isLoading = false;

  /// Image upload management
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  final List<String> _categories = ['Wellness', 'Fitness', 'Kids', 'Workshops'];

  @override
  void initState() {
    super.initState();
    _loadOwnedClubs();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _guestPriceController.dispose();
    _memberPriceController.dispose();
    _capacityController.dispose();
    _pointsController.dispose();
    _imageUrlController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  /// Loads approved clubs owned by current user for activity assignment
  Future<void> _loadOwnedClubs() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final clubs = await _clubService.getApprovedOwnedClubs(ownerId: user.uid);

      setState(() {
        _ownedClubs = clubs;
        _isLoading = false;
      });

      if (clubs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You have no approved clubs yet. Please wait for admin approval or create a club.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading clubs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Loads active facilities for selected club with capacity information
  Future<void> _loadFacilities(String clubId) async {
    try {
      final facilities = await _facilityService.getClubFacilities(
        clubId: clubId,
      );

      final activeFacilities = facilities.where((f) => f.isActive).toList();

      setState(() {
        _facilities = activeFacilities;
        _selectedFacility = null;
      });

      if (activeFacilities.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This club has no active facilities. Please add a facility first.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
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

  /// Date selection with future date restriction for activity scheduling
  Future<void> _selectDate() async {
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

  /// Time selection for activity scheduling
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

  /// Calculates and displays activity end time based on duration
  String _calculateEndTime() {
    try {
      final duration = int.tryParse(_durationController.text);
      if (duration == null || duration <= 0) {
        return 'Enter a valid duration to see end time';
      }

      final startMinutes = _selectedTime.hour * 60 + _selectedTime.minute;
      final endMinutes = startMinutes + duration;
      final endHour = (endMinutes ~/ 60) % 24;
      final endMinute = endMinutes % 60;

      final startTime =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      final endTime =
          '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

      return 'Activity time: $startTime - $endTime';
    } catch (e) {
      return 'Enter a valid duration';
    }
  }

  /// Adds activity requirement through dialog interface
  void _addRequirement() {
    showDialog(
      context: context,
      builder: (context) {
        var requirement = '';
        return AlertDialog(
          title: const Text('Add Requirement'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g., Yoga mat, Water bottle',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => requirement = value,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                setState(() => _requirements.add(value));
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (requirement.isNotEmpty) {
                  setState(() => _requirements.add(requirement));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// Removes requirement from activity list
  void _removeRequirement(int index) {
    setState(() {
      _requirements.removeAt(index);
    });
  }

  /// Builds comprehensive image upload section with validation requirements
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Activity Image'),
        const SizedBox(height: 8),

        /// Image upload requirements and guidelines
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
                  ImageUploadService.getValidationRequirements(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        /// Image preview area with fallback placeholder
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              style: _uploadedImageUrl != null
                  ? BorderStyle.solid
                  : BorderStyle.solid,
            ),
          ),
          child: _uploadedImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _uploadedImageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error, size: 50),
                      );
                    },
                  ),
                )
              : Container(
                  color: Colors.grey[50],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
        ),

        const SizedBox(height: 12),

        /// Image management controls
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
                      : _uploadedImageUrl != null
                      ? 'Change Image'
                      : 'Upload Image',
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
    );
  }

  /// Handles image upload process with temporary ID generation
  Future<void> _uploadImage() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();

      final imageUrl = await ImageUploadService.pickAndUploadImage(
        type: 'activities',
        id: tempId,
        context: context,
      );

      if (imageUrl != null) {
        setState(() {
          _uploadedImageUrl = imageUrl;
        });
      }
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  /// Removes uploaded image with storage cleanup
  void _removeImage() {
    if (_uploadedImageUrl != null) {
      ImageUploadService.deleteImage(_uploadedImageUrl!);
      setState(() {
        _uploadedImageUrl = null;
      });
    }
  }

  /// Creates new activity with comprehensive validation and capacity checks
  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClub == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a club'),
          backgroundColor: Colors.red,
        ),
      );
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      /// Facility capacity validation
      final capacity = int.parse(_capacityController.text);
      if (capacity > _selectedFacility!.maxCapacity) {
        throw Exception(
          'Capacity ($capacity) exceeds facility maximum (${_selectedFacility!.maxCapacity})',
        );
      }

      /// Time formatting and duration calculation
      final timeString =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      final duration = int.parse(_durationController.text);

      /// Activity object creation with all required fields
      final activity = Activity(
        id: '',
        clubId: _selectedClub!.id,
        facilityId: _selectedFacility!.id,
        clubName: _selectedClub!.name,
        facilityName: _selectedFacility!.title,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        date: _selectedDate,
        time: timeString,
        duration: duration,
        timeCategory: Activity.getTimeCategory(timeString),
        capacity: capacity,
        guestPrice: double.parse(_guestPriceController.text),
        memberPrice: double.parse(_memberPriceController.text),
        pointsReward: int.parse(_pointsController.text),
        requirements: _requirements,
        imageUrl: _uploadedImageUrl ?? _getDefaultImage(_selectedCategory),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: user.uid,
      );

      /// Firestore creation with business rule validation
      await ActivityService.createActivity(
        activity: activity,
        currentUserId: user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating activity: $e'),
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

  /// Provides category-appropriate default images for activities
  String _getDefaultImage(String category) {
    switch (category) {
      case 'Wellness':
        return 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=300&h=200&fit=crop';
      case 'Fitness':
        return 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=300&h=200&fit=crop';
      case 'Kids':
        return 'https://images.unsplash.com/photo-1566104827745-7237210ee915?w=300&h=200&fit=crop';
      case 'Workshops':
        return 'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=300&h=200&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=300&h=200&fit=crop';
    }
  }

  /// Standardized section title styling
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
        title: const Text('Add New Activity'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Information'),

              const SizedBox(height: 16),

              /// Club and facility selection with capacity constraints
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Club & Facility',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Club>(
                        initialValue: _selectedClub,
                        decoration: const InputDecoration(
                          labelText: 'Select Club *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: _ownedClubs.map((club) {
                          return DropdownMenuItem(
                            value: club,
                            child: Text(club.name),
                          );
                        }).toList(),
                        onChanged: (club) {
                          setState(() {
                            _selectedClub = club;
                            if (club != null) {
                              _loadFacilities(club.id);
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a club';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Facility>(
                        initialValue: _selectedFacility,
                        decoration: InputDecoration(
                          labelText: 'Select Facility *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_city),
                          helperText: _selectedFacility != null
                              ? 'Max capacity: ${_selectedFacility!.maxCapacity} people'
                              : null,
                        ),
                        items: _facilities.map((facility) {
                          return DropdownMenuItem(
                            value: facility,
                            child: Text(
                              '${facility.title} (Max: ${facility.maxCapacity})',
                            ),
                          );
                        }).toList(),
                        onChanged: _selectedClub == null
                            ? null
                            : (facility) {
                                setState(() {
                                  _selectedFacility = facility;
                                });
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a facility';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// Activity information and categorization
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Activity Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter activity name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
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

              /// Scheduling configuration with end time calculation
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Date'),
                        subtitle: Text(
                          DateFormat('EEEE, MMM d, y').format(_selectedDate),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _selectDate,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Time'),
                        subtitle: Text(_selectedTime.format(context)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _selectTime,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      /// Duration input with end time preview
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: TextFormField(
                          controller: _durationController,
                          decoration: InputDecoration(
                            labelText: 'Duration (minutes) *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.timer),
                            helperText: _calculateEndTime(),
                            helperMaxLines: 2,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter duration';
                            }
                            final duration = int.tryParse(value);
                            if (duration == null || duration < 15) {
                              return 'Duration must be at least 15 minutes';
                            }
                            if (duration > 480) {
                              return 'Duration cannot exceed 8 hours (480 min)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// Capacity and pricing structure configuration
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Capacity & Pricing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _capacityController,
                        decoration: InputDecoration(
                          labelText: 'Capacity *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.people),
                          helperText: _selectedFacility != null
                              ? 'Maximum: ${_selectedFacility!.maxCapacity}'
                              : null,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter capacity';
                          }
                          final capacity = int.tryParse(value);
                          if (capacity == null || capacity <= 0) {
                            return 'Please enter a valid number';
                          }
                          if (_selectedFacility != null &&
                              capacity > _selectedFacility!.maxCapacity) {
                            return 'Exceeds facility max (${_selectedFacility!.maxCapacity})';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      /// Dual pricing structure for guest and member rates
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _guestPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Guest Price (CHF) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.euro),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price < 0) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _memberPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Member Price (CHF) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.card_membership),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price < 0) {
                                  return 'Invalid';
                                }
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
                          prefixIcon: Icon(Icons.star),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter points reward';
                          }
                          final points = int.tryParse(value);
                          if (points == null || points < 0) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// Activity requirements and prerequisites management
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Requirements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addRequirement,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      if (_requirements.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No requirements added',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...List.generate(_requirements.length, (index) {
                          return ListTile(
                            leading: const Icon(Icons.check_circle_outline),
                            title: Text(_requirements[index]),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeRequirement(index),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildImageSection(),

              const SizedBox(height: 32),

              /// Activity creation submission
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Activity',
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
