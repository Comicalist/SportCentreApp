import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/voucher.dart';
import '../../services/voucher_service.dart';
import '../../models/club.dart';
import '../../services/club_service.dart';

class VoucherManagementScreen extends StatefulWidget {
  const VoucherManagementScreen({super.key});

  @override
  State<VoucherManagementScreen> createState() => _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  final ClubService _clubService = ClubService(); // Add instance
  List<Voucher> _vouchers = [];
  List<Club> _clubs = [];
  bool _isLoading = true;
  String? _selectedClubId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.firebaseUser?.uid;
      
      if (userId != null) {
        // Load clubs owned by this user - use instance method
        _clubs = await _clubService.getApprovedOwnedClubs(ownerId: userId);
        
        // Load vouchers for all clubs - using static method
        _vouchers = await VoucherService.getVouchersByClubOwner(userId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vouchers'),
        backgroundColor: Colors.green.shade50,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clubs.isEmpty
              ? _buildNoClubsMessage()
              : _buildVoucherList(),
      floatingActionButton: _clubs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateVoucherDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Voucher'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildNoClubsMessage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Approved Clubs Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'You need to have approved clubs before managing vouchers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList() {
    if (_vouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Vouchers Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first voucher to start earning customer loyalty!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateVoucherDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create First Voucher'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vouchers.length,
        itemBuilder: (context, index) {
          final voucher = _vouchers[index];
          return _buildVoucherCard(voucher);
        },
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    final club = _clubs.firstWhere(
      (c) => c.id == voucher.clubId,
      orElse: () => Club(
        id: voucher.clubId,
        name: 'Unknown Club',
        ownerId: '',
        createdAt: DateTime.now(),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: voucher.type == VoucherType.fitness 
                        ? Colors.teal.shade100 
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    voucher.type == VoucherType.fitness ? 'FITNESS' : 'STUFF',
                    style: TextStyle(
                      color: voucher.type == VoucherType.fitness 
                          ? Colors.teal.shade700 
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleVoucherAction(action, voucher),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_off, size: 20),
                          SizedBox(width: 8),
                          Text('Toggle Active'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              voucher.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              voucher.description,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  Icons.local_offer,
                  '${voucher.amount.toStringAsFixed(0)} CHF',
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.stars,
                  '${voucher.pointsCost} points',  // Changed from voucher.value to voucher.pointsCost
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.business,
                  club.name,
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  voucher.isActive ? Icons.check_circle : Icons.pause_circle,
                  color: voucher.isActive ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  voucher.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: voucher.isActive ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Created: ${_formatDate(voucher.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateVoucherDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateVoucherDialog(
        clubs: _clubs,
        onVoucherCreated: _loadData,
      ),
    );
  }

  void _handleVoucherAction(String action, Voucher voucher) async {
    switch (action) {
      case 'edit':
        _showEditVoucherDialog(voucher);
        break;
      case 'toggle':
        await _toggleVoucherStatus(voucher);
        break;
      case 'delete':
        _showDeleteConfirmation(voucher);
        break;
    }
  }

  void _showEditVoucherDialog(Voucher voucher) {
    showDialog(
      context: context,
      builder: (context) => _CreateVoucherDialog(
        clubs: _clubs,
        onVoucherCreated: _loadData,
        existingVoucher: voucher,
      ),
    );
  }

  Future<void> _toggleVoucherStatus(Voucher voucher) async {
    try {
      await VoucherService.updateVoucher(
        voucher.id,
        {'isActive': !voucher.isActive},
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              voucher.isActive 
                  ? 'Voucher deactivated' 
                  : 'Voucher activated',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating voucher: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(Voucher voucher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voucher'),
        content: Text(
          'Are you sure you want to delete "${voucher.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteVoucher(voucher);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVoucher(Voucher voucher) async {
    try {
      await VoucherService.deleteVoucher(voucher.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting voucher: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CreateVoucherDialog extends StatefulWidget {
  final List<Club> clubs;
  final VoidCallback onVoucherCreated;
  final Voucher? existingVoucher;

  const _CreateVoucherDialog({
    required this.clubs,
    required this.onVoucherCreated,
    this.existingVoucher,
  });

  @override
  State<_CreateVoucherDialog> createState() => _CreateVoucherDialogState();
}

class _CreateVoucherDialogState extends State<_CreateVoucherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  String? _selectedClubId;
  VoucherType _selectedType = VoucherType.fitness;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingVoucher != null) {
      final voucher = widget.existingVoucher!;
      _titleController.text = voucher.title;
      _descriptionController.text = voucher.description;
      _amountController.text = voucher.amount.toStringAsFixed(0);
      _selectedClubId = voucher.clubId;
      _selectedType = voucher.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingVoucher != null ? 'Edit Voucher' : 'Create New Voucher'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedClubId,
                decoration: const InputDecoration(
                  labelText: 'Select Club',
                  border: OutlineInputBorder(),
                ),
                items: widget.clubs.map((club) {
                  return DropdownMenuItem(
                    value: club.id,
                    child: Text(club.name),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedClubId = value),
                validator: (value) => value == null ? 'Please select a club' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<VoucherType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Voucher Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: VoucherType.fitness,
                    child: Text('Fitness (for activity bookings)'),
                  ),
                  DropdownMenuItem(
                    value: VoucherType.stuff,
                    child: Text('Stuff (for physical items)'),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., 5 CHF off Fitness Classes',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what this voucher offers',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) => value?.isEmpty == true ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (CHF)',
                  hintText: 'e.g., 5',
                  border: OutlineInputBorder(),
                  suffixText: 'CHF',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Please enter an amount';
                  final amount = double.tryParse(value!);
                  if (amount == null || amount <= 0) return 'Please enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Points cost: ${_calculatePoints()} points (100 points = 1 CHF)',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveVoucher,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingVoucher != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  int _calculatePoints() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    return (amount * 100).round(); // 100 points = 1 CHF
  }

  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.firebaseUser?.uid;
      
      if (userId == null) throw Exception('User not authenticated');

      final amount = double.parse(_amountController.text);
      final points = _calculatePoints();

      if (widget.existingVoucher != null) {
        // Update existing voucher
        await VoucherService.updateVoucher(widget.existingVoucher!.id, {
          'clubId': _selectedClubId!,
          'type': _selectedType.toString().split('.').last,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'amount': amount,
          'pointsCost': points,  // Changed from 'value' to 'pointsCost'
        });
      } else {
        // Create new voucher
        await VoucherService.createVoucherType(
          clubId: _selectedClubId!,
          createdBy: userId,
          type: _selectedType,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          amount: amount,
          pointsCost: points,  // Changed from 'value' to 'pointsCost'
        );
      }

      widget.onVoucherCreated();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingVoucher != null 
                  ? 'Voucher updated successfully!' 
                  : 'Voucher created successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving voucher: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}