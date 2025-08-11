import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/classes/main_classes/teams.dart';
import 'package:raw_threads/providers/teams_provider.dart';
import 'package:collection/collection.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  final TextEditingController _adminCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TeamProvider>().loadTeamData();
  }

  @override
  void dispose() {
    _adminCodeController.dispose();
    super.dispose();
  }

  Future<void> _linkAdminCode(BuildContext context, TeamProvider provider) async {
    final code = _adminCodeController.text.trim();
    print("[DEBUG] _linkAdminCode called with code: '$code'");

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("[DEBUG] No authenticated user found. Aborting.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }
    print("[DEBUG] Current user UID: ${user.uid}");

    final dbRef = FirebaseDatabase.instance.ref();

    try {
      print("[DEBUG] Querying admins where admincode == '$code'");
      final adminSnapshot = await dbRef
          .child('admins')
          .orderByChild('admincode')
          .equalTo(code)
          .get();

      print("[DEBUG] adminSnapshot exists: ${adminSnapshot.exists}");
      print("[DEBUG] adminSnapshot value: ${adminSnapshot.value}");

      if (adminSnapshot.exists) {
        final adminsMap = adminSnapshot.value as Map<dynamic, dynamic>;
        print("[DEBUG] adminsMap keys: ${adminsMap.keys}");
        final adminUid = adminsMap.keys.first as String;
        print("[DEBUG] Found admin UID: $adminUid");

        print("[DEBUG] Updating user's linkedAdminId to: $adminUid");
        await dbRef.child('users/${user.uid}').update({'linkedAdminId': adminUid});
        print("[DEBUG] User's linkedAdminId updated.");

        print("[DEBUG] Reloading TeamProvider data...");
        await provider.loadTeamData();
        print("[DEBUG] TeamProvider data reloaded.");

        print("[DEBUG] Initializing DanceInventoryProvider for adminUid...");
        await context.read<DanceInventoryProvider>().init(adminUid);
        print("[DEBUG] DanceInventoryProvider initialized.");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully linked to admin $code')),
        );
        _adminCodeController.clear();
      } else {
        print("[DEBUG] No admin found with code '$code'");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin Code Error')),
        );
      }
    } catch (e, stack) {
      print("[ERROR] Exception while querying admins: $e");
      print(stack);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to link admin code')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeamProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.role == 'admin') {
      return _adminView(provider);
    } else {
      return _userView(provider);
    }
  }

  void _showEditTeamDialog(BuildContext context, TeamProvider provider, Teams team) {
    final controller = TextEditingController(text: team.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Team Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Team Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != team.title) {
                provider.renameTeam(team.id, newName);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTeam(BuildContext context, TeamProvider provider, Teams team) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete the team "${team.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteTeam(team.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _adminView(TeamProvider provider) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teams')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Admin Code: ${provider.adminCode}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Team'),
              onPressed: () => _showAddTeamDialog(context, provider),
            ),
            const Divider(),
            if (provider.unassignedUsers.isNotEmpty) ...[
              const Text('Unassigned Users:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: provider.unassignedUsers.map((user) {
                  return ActionChip(
                    label: Text(user['username'] ?? 'Unknown'),
                    onPressed: () => _showAssignUserDialog(context, provider, user['uid']!),
                  );
                }).toList(),
              ),
              const Divider(),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: provider.teams.length,
                itemBuilder: (context, index) {
                  final team = provider.teams[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(team.title,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                tooltip: 'Edit Team',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditTeamDialog(context, provider, team),
                              ),
                              IconButton(
                                tooltip: 'Delete Team',
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDeleteTeam(context, provider, team),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Members:',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                    ...team.members.map((uid) {
                                      final username = provider.usernameFor(uid);
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Expanded(child: Text(username)),
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                                            tooltip: 'Remove User from Team',
                                            onPressed: () {
                                              provider.removeUserFromTeam(uid, team.id);
                                            },
                                          ),
                                          PopupMenuButton<String>(
                                            tooltip: 'Move User to Another Team',
                                            icon: const Icon(Icons.swap_horiz),
                                            onSelected: (newTeamId) {
                                              provider.assignUserToTeam(uid, newTeamId);
                                            },
                                            itemBuilder: (context) {
                                              return provider.teams
                                                  .where((t) => t.id != team.id)
                                                  .map((t) => PopupMenuItem(
                                                        value: t.id,
                                                        child: Text(t.title),
                                                      ))
                                                  .toList();
                                            },
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Consumer<DanceInventoryProvider>(
                                  builder: (context, danceProvider, child) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Assigned Dances:',
                                            style: TextStyle(fontWeight: FontWeight.bold)),
                                        if (team.assigned.isEmpty)
                                          const Text('No dances assigned'),
                                        ...team.assigned.map((danceId) {
                                          final dance = danceProvider.getDanceById(danceId);
                                          final danceName = dance?.title ?? 'Unknown Dance';
                                          return Text(danceName);
                                        }),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userView(TeamProvider provider) {
    final team = provider.teams
        .firstWhereOrNull((t) => t.id == provider.assignedTeamId);

    return Scaffold(
      appBar: AppBar(title: const Text('My Team')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (team == null)
                const Center(child: Text('You are not assigned to any team yet.'))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team: ${team.title}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Members:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...team.members.map((uid) => Text(provider.usernameFor(uid))),
                    const SizedBox(height: 16),
                    const Text('Assigned Dances:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...team.assigned.map((danceId) => Text(danceId)),
                    const SizedBox(height: 32),
                  ],
                ),

              const Divider(),
              const Text('Link to Another Admin',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              TextField(
                controller: _adminCodeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Admin Code',
                  hintText: 'Enter admin code to link',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _linkAdminCode(context, provider),
                child: const Text('Link Admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTeamDialog(BuildContext context, TeamProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Team'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Team Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.addTeam(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAssignUserDialog(
      BuildContext context, TeamProvider provider, String userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Assign User to Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: provider.teams.map((team) {
            return ListTile(
              title: Text(team.title),
              onTap: () {
                provider.assignUserToTeam(userId, team.id);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
