import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/classes/main_classes/teams.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';
import 'package:raw_threads/providers/teams_provider.dart';
import 'package:raw_threads/account/app_state.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/sidebar/sidebar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:raw_threads/pages/profile_builds/member_profile.dart';

class TeamsPage extends StatefulWidget {
  final String role;
  const TeamsPage({super.key, required this.role});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  final TextEditingController _adminCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<TeamProvider>();
    provider.init();
  }

  @override
  void dispose() {
    _adminCodeController.dispose();
    super.dispose();
  }

  Future<void> _linkAdminCode(BuildContext context, TeamProvider provider) async {
    final code = _adminCodeController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dbRef = FirebaseDatabase.instance.ref();
    final adminSnapshot = await dbRef.child('admins').orderByChild('admincode').equalTo(code).get();

    if (adminSnapshot.exists) {
      final adminUid = (adminSnapshot.value as Map).keys.first as String;
      await dbRef.child('users/${user.uid}').update({'linkedAdminId': adminUid});
      context.read<AppState>().setAdminId(adminUid);
      await context.read<TeamProvider>().init();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Linked to admin $code')));
      _adminCodeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid admin code')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamProvider>(builder: (context, provider, _) {
      if (provider.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

      return widget.role == 'admin' ? _adminView(provider) : _userView(provider);
    });
  }

Widget _adminView(TeamProvider provider) {
  return Scaffold(
    backgroundColor: myColors.secondary,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: myColors.secondary,
      title: Image.asset('assets/logotype_green.png', height: 20),
      actions: [
        Builder(
          builder: (context) =>
              IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openEndDrawer()),
        )
      ],
    ),
    endDrawer: Sidebar(role: widget.role),
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Teams', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Vogun')),
          const SizedBox(height: 10),
          Text('Admin Code: ${provider.adminCode}', style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Team'),
            onPressed: () => _showAddTeamDialog(context, provider),
          ),
          const Divider(),
          // --- Unassigned Users (outside team cards) ---
          if (provider.unassignedUsers.isNotEmpty) ...[
            const Text('Unassigned Users:', style: TextStyle(fontWeight: FontWeight.bold)),
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

          // --- Team list ---
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
                              child: Text(
                                team.title,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditTeamDialog(context, provider, team),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteTeam(context, provider, team),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // --- Members ---
                        const Text('Members:', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (team.members.isEmpty)
                          const Text('No members assigned')
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: team.members.map((uid) {
                              final username = provider.usernameFor(uid);
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MemberProfile(userId: uid),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    username,
                                    style: TextStyle(fontSize: 16, color: myColors.primary),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 8),
                        // --- Assigned Dances ---
                        const Text('Assigned Dances:', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (team.assigned.isEmpty)
                          const Text('No dances assigned')
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: team.assigned.map((danceId) {
                              final danceProvider = context.read<DanceInventoryProvider>();
                              final dance = danceProvider.getDanceById(danceId);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  dance!.title,
                                  style: TextStyle(fontSize: 16, color: myColors.primary),
                                ),
                              );
                            }).toList(),
                          ),
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
    final team = provider.teams.firstWhere((t) => t.id == provider.assignedTeamId, orElse: () => Teams(id: '', title: 'No team assigned', members: [], assigned: []));

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: myColors.secondary,
        title: Image.asset('assets/logotype_green.png', height: 20),
        actions: [Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openEndDrawer()))],
      ),
      endDrawer: Sidebar(role: widget.role),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Team', style: TextStyle(fontFamily: "Vogun", fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    team.id.isEmpty
                        ? const Text('You are not assigned to any team yet.')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(team.title, style: const TextStyle(fontSize: 20, color: Colors.black87)),
                              const SizedBox(height: 16),
                              const Text('Members:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ...team.members.map((uid) {
                                final username = provider.usernameFor(uid);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(username, style: const TextStyle(fontSize: 16)),
                                );
                              }),
                            ],
                          ),
                    team.assigned.isEmpty
                        ? const Text('No dances assigned')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: team.assigned.map((danceId) {
                              final danceProvider = context.read<DanceInventoryProvider>();
                              final dance = danceProvider.getDanceById(danceId);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  dance!.title,
                                  style: TextStyle(fontSize: 16, color: myColors.primary),
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),

            // Bottom section pinned after scrollable content
            const Divider(),
            Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Link to Another Admin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _adminCodeController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Admin Code',
                      hintText: 'Enter admin code to link'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                    onPressed: () => _linkAdminCode(context, provider),
                    child: const Text('Link Admin')),
              ],
            ),
          ),
        ],
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
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Team Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) provider.addTeam(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAssignUserDialog(BuildContext context, TeamProvider provider, String userId) {
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

  void _showEditTeamDialog(BuildContext context, TeamProvider provider, Teams team) {
    final controller = TextEditingController(text: team.title);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Edit Team'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Title ---
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: "Team Name"),
                ),
                const SizedBox(height: 16),
                // --- Assigned dances ---
                const Text("Assigned Dances", style: TextStyle(fontWeight: FontWeight.bold)),
                team.assigned.isEmpty
                    ? const Text("No dances assigned.")
                    : Column(
                        children: team.assigned.map((danceId) {
                          final danceProvider = context.read<DanceInventoryProvider>();
                          final dance = danceProvider.getDanceById(danceId);
                          return ListTile(
                            title: Text(dance!.title),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                provider.unassignDanceFromTeam(team.id, danceId);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 16),

                // --- Team members ---
                const Text("Team Members", style: TextStyle(fontWeight: FontWeight.bold)),
                team.members.isEmpty
                    ? const Text("No members in this team.")
                    : Column(
                        children: team.members.map((uid) {
                          final username = provider.usernameFor(uid);
                          return ListTile(
                            title: Text(username),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                provider.removeUserFromTeam(uid, team.id);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != team.title) {
                  provider.renameTeam(team.id, newName);
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteTeam(BuildContext context, TeamProvider provider, Teams team) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete the team "${team.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.deleteTeam(team.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: myColors.secondary))),
          ],
        ),
    );
  }
}
