import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';

import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/pages/costume_builds/costume_page.dart';
import 'package:raw_threads/pages/dance_builds/add_generic_dialog.dart';
import 'package:raw_threads/account/app_state.dart';

import 'package:raw_threads/providers/dance_inventory_provider.dart';
import 'package:raw_threads/providers/costume_provider.dart';
import 'package:raw_threads/providers/teams_provider.dart';

class GenericDancePage extends StatefulWidget {
  final String role;
  final Dances dance;
  final void Function(Dances) onDelete; // Called in parent page to update UI

  const GenericDancePage({
    super.key,
    required this.role,
    required this.onDelete,
    required this.dance,
  });

  @override
  State<GenericDancePage> createState() => _GenericDancePageState();
}

class _GenericDancePageState extends State<GenericDancePage> {
  late Dances dance;
  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    dance = widget.dance;
  }

  ImageProvider? _buildImage(String? path) {
    if (path == null) return null;
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  void _editDancePage() {
    showDialog(
      context: context,
      builder: (_) => AddGenericDialog(
        dance: dance,
        onSubmit: (updatedDance) async {
          final provider = context.read<DanceInventoryProvider>();
          await provider.update(updatedDance);
          if (!mounted) return;
          setState(() => dance = updatedDance);
        },
      ),
    );
  }

  void _showAssignDanceToTeamDialog(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    final filteredTeams = teamProvider.teams.where((t) => t.title.trim().isNotEmpty).toList();
    final selectedTeamIds = <String>{
      for (final team in teamProvider.teams)
        if (team.assigned.contains(dance.id)) team.id
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Assign Dance to Teams'),
              content: SizedBox(
                width: double.maxFinite,
                child: Consumer<TeamProvider>(
                  builder: (context, provider, child) {
                    if (provider.teams.isEmpty) {
                      return const Text('No teams available. Please add teams first.');
                    }
                    return ListView(
                      shrinkWrap: true,
                      children: filteredTeams.map((team) {
                        final isSelected = selectedTeamIds.contains(team.id);
                        return CheckboxListTile(
                          title: Text(team.title),
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedTeamIds.add(team.id);
                              } else {
                                selectedTeamIds.remove(team.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    for (final team in teamProvider.teams) {
                      await teamProvider.unassignDanceFromTeam(team.id, dance.id);
                    }
                    for (final teamId in selectedTeamIds) {
                      await teamProvider.assignDanceToTeam(teamId, dance.id);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Assign to Team'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DanceInventoryProvider>();
    final updatedDance = provider.getDanceById(dance.id);
    
    if (updatedDance != null) dance = updatedDance;

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: myColors.secondary,
        title: Text(
          dance.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 32,
            fontFamily: 'Vogun',
          ),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              tooltip: 'Delete Dance',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Dance?'),
                    content: Text('Are you sure you want to delete "${dance.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await provider.delete(dance.id);
                          widget.onDelete(dance);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (isAdmin)
            TextButton(
              onPressed: _editDancePage,
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontFamily: 'Raleway',
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildImageCard(dance.leftImagePath),
                const SizedBox(width: 4.0),
                _buildImageCard(dance.rightImagePath),
              ],
            ),
            const SizedBox(height: 14),
            _buildInfoText(dance.title, fontSize: 28, isBold: true),
            _buildInfoText(dance.country, fontSize: 16),
            const SizedBox(height: 24),
            _buildButton(context, 'Men'),
            const SizedBox(height: 8),
            _buildButton(context, 'Women'),
            const Spacer(),
            if (isAdmin)
              SizedBox(
                width: 337,
                height: 60,
                child: OutlinedButton(
                  onPressed: () => _showAssignDanceToTeamDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: myColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Assign to Team'),
                ),
              ),
            const SizedBox(height: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String? imagePath) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 170.5,
        height: 325,
        decoration: BoxDecoration(
          color: const Color(0xFFFEFEFE),
          borderRadius: BorderRadius.circular(16),
          image: _buildImage(imagePath) != null
              ? DecorationImage(
                  image: _buildImage(imagePath)!,
                  fit: BoxFit.cover,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildInfoText(String text, {double fontSize = 15, bool isBold = false, String fontFamily = 'Raleway'}) {
    return Container(
      width: 337,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
          color: const Color(0xFF191B1A),
        ),
      ),
    );
  }

  // Remove the adminId parameter from _buildButton
  Widget _buildButton(BuildContext context, String label) {
    final adminId = context.read<AppState>().adminId;
    final costumesProvider = context.watch<CostumesProvider>();

    return SizedBox(
      width: 337,
      height: 60,
      child: ElevatedButton(
        onPressed: adminId == null
            ? null
            : () async {
              await costumesProvider.init(danceId: dance.id, gender: label);
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CostumePage(
                        role: widget.role,
                        dance: dance,
                        gender: label,
                      ),
                    ),
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: myColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
