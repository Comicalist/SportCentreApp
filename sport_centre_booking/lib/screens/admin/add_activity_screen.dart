import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';
import '../../services/activity_service.dart';
import '../../utils/constants.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clubController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeController = TextEditingController(text: '09:00');
  final _guestPriceController = TextEditingController();
  final _memberPriceController = TextEditingController();
  final _pointsController = TextEditingController();
  final _capacityController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  String _selectedCategory = 'Wellness';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;
  final List<String> _requirements = [];
  final _requirementController = TextEditingController();

  final List<String> _categories = ['Wellness', 'Fitness', 'Kids', 'Workshops'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _clubController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _guestPriceController.dispose();
    _memberPriceController.dispose();
    _pointsController.dispose();
    _capacityController.dispose();
    _imageUrlController.dispose();
    _requirementController.dispose();
    super.dispose();
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
              _buildTextField(
                controller: _nameController,
                label: 'Activity Name',
                icon: Icons.event,
                hint: 'e.g., Morning Yoga Flow',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
                hint: 'Describe the activity...',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Location & Time'),
              _buildTextField(
                controller: _clubController,
                label: 'Club',
                icon: Icons.groups,
                hint: 'e.g., Yoga Club',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                icon: Icons.location_on,
                hint: 'e.g., Downtown Sports Club',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildTimePicker(),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Pricing & Capacity'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _guestPriceController,
                      label: 'Guest Price',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      hint: '25.00',
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (double.tryParse(value!) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _memberPriceController,
                      label: 'Member Price',
                      icon: Icons.card_membership,
                      keyboardType: TextInputType.number,
                      hint: '20.00',
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (double.tryParse(value!) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _pointsController,
                      label: 'Points Reward',
                      icon: Icons.star,
                      keyboardType: TextInputType.number,
                      hint: '50',
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (int.tryParse(value!) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _capacityController,
                      label: 'Capacity',
                      icon: Icons.people,
                      keyboardType: TextInputType.number,
                      hint: '15',
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        final capacity = int.tryParse(value!);
                        if (capacity == null || capacity <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Additional Information'),
              _buildTextField(
                controller: _imageUrlController,
                label: 'Image URL (optional)',
                icon: Icons.image,
                hint: 'https://images.unsplash.com/photo-...',
              ),
              const SizedBox(height: 16),
              _buildRequirementsSection(),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Activity',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.filterBorderRadius),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.filterBorderRadius),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.filterBorderRadius),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate)),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(_timeController.text.split(':')[0]),
            minute: int.parse(_timeController.text.split(':')[1]),
          ),
        );
        if (picked != null) {
          setState(() {
            _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Time',
          prefixIcon: const Icon(Icons.access_time),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.filterBorderRadius),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Text(_timeController.text),
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requirements (optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _requirementController,
                decoration: InputDecoration(
                  hintText: 'Add a requirement',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.filterBorderRadius),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addRequirement,
              icon: const Icon(Icons.add_circle, color: Colors.teal),
              iconSize: 32,
            ),
          ],
        ),
        if (_requirements.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _requirements.map((req) {
              return Chip(
                label: Text(req),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _requirements.remove(req);
                  });
                },
                backgroundColor: Colors.teal[50],
                deleteIconColor: Colors.teal[700],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _addRequirement() {
    if (_requirementController.text.trim().isNotEmpty) {
      setState(() {
        _requirements.add(_requirementController.text.trim());
        _requirementController.clear();
      });
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final capacity = int.parse(_capacityController.text);
      
      // Default image URL based on category if not provided
      String imageUrl = _imageUrlController.text.trim();
      if (imageUrl.isEmpty) {
        imageUrl = _getDefaultImageUrl(_selectedCategory);
      }

      final newActivity = Activity(
        id: '', // Will be generated by Firestore
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        club: _clubController.text.trim(),
        date: _selectedDate,
        time: _timeController.text,
        timeCategory: Activity.getTimeCategory(_timeController.text),
        location: _locationController.text.trim(),
        price: double.parse(_guestPriceController.text),
        guestPrice: double.parse(_guestPriceController.text),
        memberPrice: double.parse(_memberPriceController.text),
        pointsReward: int.parse(_pointsController.text),
        capacity: capacity,
        bookedCount: 0,
        spotsLeft: capacity,
        imageUrl: imageUrl,
        requirements: _requirements,
      );

      await ActivityService.addActivity(newActivity);

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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getDefaultImageUrl(String category) {
    switch (category) {
      case 'Wellness':
        return 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=200&fit=crop';
      case 'Fitness':
        return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=300&h=200&fit=crop';
      case 'Kids':
        return 'https://images.unsplash.com/photo-1530549387789-4c1017266635?w=300&h=200&fit=crop';
      case 'Workshops':
        return 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=300&h=200&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=200&fit=crop';
    }
  }
}