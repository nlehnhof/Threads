import 'package:flutter/material.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/pages/assignment_builds/add_edit_assignments.dart';
import 'package:raw_threads/providers/app_context_provider.dart';

import 'package:raw_threads/providers/assignments_provider.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/services/costume_inventory_service.dart';

import 'package:raw_threads/classes/main_classes/assignments.dart';

class AssignPage extends StatefulWidget {
  final CostumePiece costume;
  final String role;

  const AssignPage({
    super.key, 
    required this.costume,
    required this.role,
    });

  @override
  State<AssignPage> createState() => _AssignPageState();
}

class _AssignPageState extends State<AssignPage> {
  String searchQuery = "";
  bool sortByUser = true;
  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();

  // Look up danceId & gender for this costume
    CostumeInventoryService.instance
        .findCostumePath(widget.costume.id)
        .then((path) {
      if (path != null) {
        final appContext = context.read<AppContextProvider>();
        appContext.setCostumeContext(
          gender: path['gender']!,
          costumeId: widget.costume.id,
          danceId: path['danceId']!,
        );
      } else {
        debugPrint('Costume path not found for ${widget.costume.id}');
      }
    });
  }

  Future<void> _addOrEditAssignment({Assignments? existing, int? index}) async {
    final provider = context.read<AssignmentProvider>();

    final result = await showDialog<Assignments?>(
      context: context,
      builder: (_) => AddEditAssignments(
        allowDelete: existing != null, 
        costume: widget.costume,
        onSave: (_) {},
        existing: existing,
        ),
      );

    if (result == null && existing != null && index != null) {
      await provider.deleteAssignment(existing);
    } else if (result != null) {
      if (existing != null) {
        await provider.updateAssignment(result);
      } else {
        await provider.addAssignment(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssignmentProvider>();
    final assignments = provider.assignments;

    List<Assignments> filtered = assignments
        .where((assignment) =>
          assignment.user.toLowerCase().contains(searchQuery))
        .toList();

    if (sortByUser) {
      filtered.sort((a,b) => a.user.toLowerCase().compareTo(b.user.toLowerCase()));
    }

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        title: Text('${widget.costume.title} Assignments'),
        centerTitle: true,
        actions: [
          if (widget.role == 'admin')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addOrEditAssignment,
              ),
          ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(hintText: "Search"),
              onChanged: (value) =>
                  setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final assignment = filtered[index];
                return ListTile(
                  title: Text('${assignment.number} ${widget.costume.title}'),
                  subtitle: Text('${assignment.size} | ${assignment.user}'),
                  onTap: isAdmin
                    ? () => _addOrEditAssignment(existing: assignment, index: index)
                    : null,
                  );
                }
              ),
            ),
          ],
        )
      );
    }
  }