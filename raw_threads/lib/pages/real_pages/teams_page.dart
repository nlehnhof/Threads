import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/providers/teams_provider.dart';
import 'package:collection/collection.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  @override
  void initState() {
    super.initState();
    context.read<TeamProvider>().loadTeamData();
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
                          Text(team.title,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Members:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    ...team.members.map((uid) => Text(provider.usernameFor(uid))),
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
        child: team == null
            ? const Center(child: Text('You are not assigned to any team yet.'))
            : Column(
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
