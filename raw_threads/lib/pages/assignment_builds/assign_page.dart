import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/account/app_state.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/classes/main_classes/assignments.dart';
import 'package:raw_threads/pages/assignment_builds/add_edit_assignments.dart';
import 'package:raw_threads/providers/assignments_provider.dart';
import 'package:raw_threads/providers/costume_provider.dart';

class AssignPage extends StatefulWidget {
  final CostumePiece costume;
  final String role;

  const AssignPage({super.key, required this.costume, required this.role});

  @override
  State<AssignPage> createState() => _AssignPageState();
}

class _AssignPageState extends State<AssignPage> {
  String searchQuery = "";
  bool _loading = true;
  bool get isAdmin => widget.role == 'admin';

  String danceId = "";
  String gender = "";

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    final costumeProvider = context.read<CostumesProvider>();
    final assignmentProvider = context.read<AssignmentProvider>();
    final adminId = context.read<AppState>().adminId;
    if (adminId == null) return;

    // Find the costume path
    final path = await costumeProvider.findCostumePath(widget.costume.id);
    if (path == null) {
      if (mounted) setState(() => _loading = false);
      print("❌ Could not find path for costume ${widget.costume.id}");
      return;
    }

    danceId = path['danceId'] ?? '';
    gender = path['gender'] ?? '';

    // Set AssignmentProvider context
    await assignmentProvider.setContext(
      danceId: danceId,
      gender: gender,
      costumeId: widget.costume.id,
    );

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addOrEditAssignment({Assignments? existing}) async {
    final assignmentProvider = context.read<AssignmentProvider>();

    final result = await showDialog<Assignments?>(
      context: context,
      builder: (_) => AddEditAssignments(
        allowDelete: existing != null,
        existing: existing,
        costume: widget.costume,
        onSave: (assignment) => Navigator.pop(context, assignment),
      ),
    );

    if (result == null && existing != null) {
      await assignmentProvider.deleteAssignment(existing.id);
    } else if (result != null) {
      if (existing != null) {
        await assignmentProvider.updateAssignment(result);
      } else {
        await assignmentProvider.addAssignment(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final assignmentProvider = context.watch<AssignmentProvider>();
    final assignments = assignmentProvider.assignments;

    List<Assignments> filtered = assignments
        .where((a) => a.user.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) {
        final numA = int.tryParse(a.number) ?? 0;
        final numB = int.tryParse(b.number) ?? 0;
        return numA.compareTo(numB);
      });

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        backgroundColor: myColors.secondary,
        title: Text(
          '${widget.costume.title} Assignments',
          style: const TextStyle(
            fontFamily: 'Vogun',
            color: Colors.black87,
            fontSize: 22,
          ),
        ),
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
            padding: const EdgeInsets.all(4.0),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, index) {
                final assignment = filtered[index];
                return InkWell(
                  onTap: isAdmin ? () => _addOrEditAssignment(existing: assignment) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${assignment.number} ${assignment.size}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          assignment.user,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
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
    );
  }
}
