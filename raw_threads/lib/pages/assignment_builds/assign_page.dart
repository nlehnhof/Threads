import 'package:flutter/material.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/pages/assignment_builds/add_edit_assignments.dart';

import 'package:raw_threads/providers/assignments_provider.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';

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

  Future<void> _addOrEditAssignment({Assignments? existing, int? index}) async {
    final provider = context.read<AssignmentsProvider>();

    final result = await showDialog<Assignments?>(
      context: context,
      builder: (_) => AddEditAssignments(
        allowDelete: existing != null, 
        onSave: (_) {}, 
        costume: widget.costume)
      );

    if (result == null && existing != null && index != null) {
      await provider.deleteAssignment(widget.costume.id, existing.id);
    } else if (result != null) {
      if (existing != null) {
        await provider.updateAssignment(existing);
      } else {
        await provider.addAssignment(existing!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssignmentsProvider>();
    final assignments = provider.assignments;

    List<Assignments> filtered = assignments
        .where((assignment) =>
          assignment.user.toLowerCase().contains(searchQuery))
        .toList();

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        title: Text('${widget.costume.title} Assignments}'),
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
                  onTap: _addOrEditAssignment,
                );
              }
            ),
          ),
        ],
      )
    );
  }
}


      //     Expanded(
      //       child: assignments.isEmpty
      //         ? const Center(child: Text("No Assignments"))
      //         : ListView(
      //           children: List.generate(
      //             assignments.length,
      //             (index) => _buildAssignmentCard(assignments[index], index),
      //           ),
      //         ),
      //     ),
      //   ],
      // ),
