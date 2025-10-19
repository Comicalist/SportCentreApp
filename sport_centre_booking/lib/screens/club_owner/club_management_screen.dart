import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/club.dart';
import '../../services/club_service.dart';
import '../../providers/auth_provider.dart';
import 'add_club_screen.dart';
import 'edit_club_screen.dart';
import 'club_detail_screen.dart';

class ClubManagementScreen extends StatefulWidget {
  const ClubManagementScreen({super.key});

  @override
  State<ClubManagementScreen> createState() => _ClubManagementScreenState();
}

class _ClubManagementScreenState extends State<ClubManagementScreen> {
  final ClubService _clubService = ClubService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ownerId = authProvider.appUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage My Clubs'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: FutureBuilder<List<Club>>(
              future: _clubService.getOwnedClubs(ownerId: ownerId),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final clubs = snapshot.data!
                    .where(
                      (club) => club.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

                if (clubs.isEmpty) {
                  return const Center(child: Text('No clubs found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: clubs.length,
                  itemBuilder: (context, index) => _buildClubCard(clubs[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClubScreen()),
          ).then((_) => setState(() {})); // refresh after adding
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('Add Club'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search clubs...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildClubCard(Club club) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: club.isActive ? Colors.green : Colors.grey,
          child: const Icon(Icons.business, color: Colors.white),
        ),
        title: Text(
          club.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (club.location != null && club.location!.isNotEmpty)
              Text(club.location!),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: club.isApproved ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    club.isApproved ? 'Approved' : 'Pending',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: club.isActive ? Colors.teal : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    club.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToClubDetail(club),
      ),
    );
  }

  void _navigateToClubDetail(Club club) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => ClubDetailScreen(club: club)),
    );

    // If club was deleted, refresh the list
    if (result == true) {
      setState(() {});
    }
  }
}
