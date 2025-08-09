import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/classes/main_classes/assignments.dart';
import 'package:raw_threads/pages/assignment_builds/add_edit_assignments.dart';
import 'package:raw_threads/providers/assignments_provider.dart';
import 'package:raw_threads/providers/costume_provider.dart';
import 'package:raw_threads/services/costume_inventory_service.dart';

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

  String danceId = "";
  String gender = "";
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPathAndUpdateContext();
  }

  Future<void> _loadPathAndUpdateContext() async {
    final costumeProvider = context.read<CostumesProvider>();

    // Try fast lookup from provider cache
    var path = await costumeProvider.findPath(widget.costume.id);

    // If not found locally, do full Firebase search
    if (path == null) {
      path = await CostumeInventoryService.instance
          .findCostumePath(widget.costume.id);
    }

    if (path != null) {
      danceId = path['danceId'] ?? '';
      gender = path['gender'] ?? '';
      final assignmentProvider = context.read<AssignmentProvider>();
      assignmentProvider.updateContext(
        costumeId: widget.costume.id,
        danceId: danceId,
        gender: gender,
      );
    } else {
      print("❌ Could not find path for costume ${widget.costume.id}");
      danceId = '';
      gender = '';
    }

    setState(() => _loading = false);
  }

  Future<void> _addOrEditAssignment({Assignments? existing, int? index}) async {
    if (danceId.isEmpty || gender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dance and gender not loaded yet")),
      );
      return;
    }

    final provider = context.read<AssignmentProvider>();

    final result = await showDialog<Assignments?>(
      context: context,
      builder: (_) => AddEditAssignments(
        allowDelete: existing != null,
        existing: existing,
        costume: widget.costume,
        onSave: (assignment) => Navigator.of(context).pop(assignment),
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (danceId.isEmpty || gender.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Assignments")),
        body: const Center(
          child: Text("Could not find dance/gender for this costume."),
        ),
      );
    }

    final provider = context.watch<AssignmentProvider>();
    final assignments = provider.assignments;

    List<Assignments> filtered = assignments
        .where((assignment) =>
            assignment.user.toLowerCase().contains(searchQuery))
        .toList();

    if (sortByUser) {
      filtered.sort(
          (a, b) => a.user.toLowerCase().compareTo(b.user.toLowerCase()));
    }

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        title: Text('${widget.costume.title} Assignments'),
        centerTitle: true,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addOrEditAssignment(),
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
                      ? () => _addOrEditAssignment(
                          existing: assignment, index: index)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
