import 'package:flutter/material.dart';

import '../../models/club.dart';
import '../../services/club_service.dart';

/// Club editing interface with approval workflow enforcement
/// Manages basic club information and operational status with admin approval requirements
class EditClubScreen extends StatefulWidget {
  const EditClubScreen({super.key, required this.club});
  final Club club;

  @override
  State<EditClubScreen> createState() => _EditClubScreenState();
}

class _EditClubScreenState extends State<EditClubScreen> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  bool _isActive = true;
  bool _isLoading = false;

  final ClubService _clubService = ClubService();

  @override
  void initState() {
    super.initState();
    // Initialize form with existing club data
    _nameController = TextEditingController(text: widget.club.name);
    _locationController = TextEditingController(
      text: widget.club.location ?? '',
    );
    _isActive = widget.club.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Club'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Basic club information fields
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Club Name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  const SizedBox(height: 12),
                  
                  // Admin approval status warning for unapproved clubs
                  if (!widget.club.isApproved) ...[
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Club must be approved by admin before it can be activated',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Operational status control with approval dependency
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: Text(
                      widget.club.isApproved
                          ? 'Toggle club active status'
                          : 'Cannot activate until approved by admin',
                    ),
                    value: _isActive,
                    onChanged: widget.club.isApproved
                        ? (val) => setState(() => _isActive = val)
                        : null,
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  
                  // Save changes with loading state
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateClub,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Update'),
                  ),
                ],
              ),
            ),
    );
  }

  /// Update club information with business rule validation
  /// Enforces approval requirements for activation status
  Future<void> _updateClub() async {
    // Validate required club name
    if (_nameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a club name')),
        );
      }
      return;
    }

    // Enforce admin approval requirement for activation
    if (_isActive && !widget.club.isApproved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot activate club until approved by admin'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create updated club with form data
      final updatedClub = widget.club.copyWith(
        name: _nameController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        isActive: _isActive,
      );

      await _clubService.updateClub(updatedClub);

      if (mounted) {
        Navigator.pop(context, updatedClub);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating club: $e'),
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
