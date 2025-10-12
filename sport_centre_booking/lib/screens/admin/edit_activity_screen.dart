import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';
import '../../services/activity_service.dart';
import '../../utils/constants.dart';

class EditActivityScreen extends StatefulWidget {
  final Activity activity;

  const EditActivityScreen({
    super.key,
    required this.activity,
  });

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _clubController;
  late TextEditingController _locationController;
  late TextEditingController _timeController;
  late TextEditingController _guestPriceController;
  late TextEditingController _memberPriceController;
  late TextEditingController _pointsController;
  late TextEditingController _capacityController;
  
  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;

  final List<String> _categories = ['Wellness', 'Fitness', 'Kids', 'Workshops'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.activity.name);
    _descriptionController = TextEditingController(text: widget.activity.description);
    _clubController = TextEditingController(text: widget.activity.club);
    _locationController = TextEditingController(text: widget.activity.location);
    _timeController = TextEditingController(text: widget.activity.time);
    _guestPriceController = TextEditingController(text: widget.activity.guestPrice.toString());
    _memberPriceController = TextEditingController(text: widget.activity.memberPrice.toString());
    _pointsController = TextEditingController(text: widget.activity.pointsReward.toString());
    _capacityController = TextEditingController(text: widget.activity.capacity.toString());
    
    _selectedCategory = widget.activity.category;
    _selectedDate = widget.activity.date;
  }

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Activity'),
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
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
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
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                icon: Icons.location_on,
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
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        final capacity = int.tryParse(value!);
                        if (capacity == null) return 'Invalid';
                        if (capacity < widget.activity.bookedCount) {
                          return 'Cannot be less than ${widget.activity.bookedCount}';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              _buildBookingInfo(),
              
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
                          'Save Changes',
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
      value: _selectedCategory,
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

  Widget _buildBookingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Current Booking Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Booked', '${widget.activity.bookedCount} people'),
          _buildInfoRow('Available', '${widget.activity.spotsLeft} spots'),
          _buildInfoRow('Total Capacity', '${widget.activity.capacity} people'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newCapacity = int.parse(_capacityController.text);
      final newSpotsLeft = newCapacity - widget.activity.bookedCount;

      final updatedActivity = Activity(
        id: widget.activity.id,
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
        capacity: newCapacity,
        bookedCount: widget.activity.bookedCount,
        spotsLeft: newSpotsLeft,
        imageUrl: widget.activity.imageUrl,
        requirements: widget.activity.requirements,
      );

      await ActivityService.updateActivity(updatedActivity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}