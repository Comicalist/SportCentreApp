import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/club.dart';
import '../../services/club_service.dart';
import '../../providers/auth_provider.dart';
import 'add_club_screen.dart';
import 'edit_club_screen.dart';

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
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final clubs = snapshot.data!
                    .where((club) => club.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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
        title: Text(club.name),
        subtitle: Text('Location: ${club.location}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditClubScreen(club: club)),
                ).then((_) => setState(() {})); // refresh after edit
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(club),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Club club) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Club'),
        content: Text('Are you sure you want to delete "${club.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clubService.deleteClub(clubId: club.id);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
