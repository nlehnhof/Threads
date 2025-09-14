import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:raw_threads/classes/main_classes/teams.dart';
import 'package:raw_threads/providers/teams_provider.dart';
import 'package:raw_threads/account/app_state.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/sidebar/sidebar.dart';
import 'package:raw_threads/pages/profile_builds/member_profile.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().init();
    });
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
    final codeSnap = await dbRef.child('adminCodes/$code').get();

    if (codeSnap.exists) {
      final adminUid = codeSnap.value as String;

      await dbRef.child('users/${user.uid}').update({'linkedAdminId': adminUid});
      context.read<AppState>().setAdminId(adminUid);

      await provider.init();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Linked to admin $code')));
      _adminCodeController.clear();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid admin code')));
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
  // --- Split linked users ---
  final unassignedUsers = provider.linkedUsers
      .where((u) => u.assignedTeamId == null)
      .toList();
  final assignedUsers = provider.linkedUsers
      .where((u) => u.assignedTeamId != null)
      .toList();

  return Scaffold(
    backgroundColor: myColors.secondary,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: myColors.secondary,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/logotype_green.png', height: 20),
          Text('Join Code: ${provider.adminCode}',
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer()),
        ),
      ],
    ),
    endDrawer: Sidebar(role: 'admin'),
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Users',
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Vogun')),
          const SizedBox(height: 10),
          const Divider(),

          // --- Unassigned Users ---
          if (unassignedUsers.isNotEmpty) ...[
            const Text('Unassigned Users:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: unassignedUsers.map((user) {
                return ActionChip(
                  label: Text(user.username),
                  onPressed: () => _showAssignUserDialog(context, provider, user.id),
                );
              }).toList(),
            ),
            const Divider(),
          ],

          // --- Assigned Users ---
          if (assignedUsers.isNotEmpty) ...[
            const Text('Assigned Users:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: assignedUsers.map((user) {
                return ActionChip(
                  label: Text(user.username),
                  onPressed: () {
                    // Navigate to member profile
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MemberProfile(userId: user.id),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            const Divider(),
          ],

          // --- Teams List ---
          const Text('Teams',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showEditTeamDialog(context, provider, team)),
                            IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _confirmDeleteTeam(context, provider, team)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Members
                        const Text('Members:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
                                        builder: (_) =>
                                            MemberProfile(userId: uid)),
                                  );
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(username,
                                      style: TextStyle(
                                          fontSize: 16, color: myColors.primary)),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 12),

                        // Assigned Dances
                        const Text('Assigned Dances:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        if (team.assigned.isEmpty)
                          const Text('No dances assigned')
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: team.assigned.map((danceId) {
                              final dance = context
                                  .read<DanceInventoryProvider>()
                                  .getDanceById(danceId);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(dance?.title ?? 'Unknown Dance',
                                    style: const TextStyle(fontSize: 16)),
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
    floatingActionButton: FloatingActionButton(
      backgroundColor: myColors.primary,
      foregroundColor: Colors.white,
      onPressed: () => _showAddTeamDialog(context, provider),
      child: const Icon(Icons.add),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
  );
}

  // ------------------- USER VIEW -------------------
  Widget _userView(TeamProvider provider) {
    final team = provider.teams.firstWhere(
        (t) => t.id == provider.assignedTeamId,
        orElse: () => Teams(id: '', title: 'No team assigned', members: [], assigned: []));

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
                  ],
                ),
              ),
            ),

            const Divider(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Link to Another Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  // ------------------- DIALOGS -------------------
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
          content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Team Name")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
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
