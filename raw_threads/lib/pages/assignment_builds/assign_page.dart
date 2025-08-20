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
    final adminId = context.read<AppState>().adminId;
    if (adminId == null) return;
    final path = await costumeProvider.findCostumePath(widget.costume.id, adminId);

    if (path != null) {
      danceId = path['danceId'] ?? '';
      gender = path['gender'] ?? '';

      if (mounted) {
        final assignmentProvider = context.read<AssignmentProvider>();
        assignmentProvider.setContext(
          danceId: danceId,
          gender: gender,
          costumeId: widget.costume.id,
        );
      }
    } else {
      print("❌ Could not find path for costume ${widget.costume.id}");
      danceId = '';
      gender = '';
    }

    if (mounted) {
      setState(() => _loading = false);
    }
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

    if (result == null && existing != null) {
      if (mounted) {
      await provider.deleteAssignment(existing.id);
      }
    } else if (result != null) {
      if (existing != null) {
        if (mounted) {
        await provider.updateAssignment(result);
        }
      } else {
        if (mounted) {
        await provider.addAssignment(result);
        }
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
        backgroundColor: myColors.secondary,
        appBar: AppBar(
          title: Text(
            "Assignments",
          style: TextStyle(
            fontFamily: 'Vogun',
            color: Colors.black87,
            fontSize: 22,
            ),
          ),
        ),
        body: const Center(
          child: Text("Could not find dance/gender for this costume."),
        ),
      );
    }

    final provider = context.watch<AssignmentProvider>();
    final assignments = provider.assignments;

    // Filter assignments by user search query (case-insensitive)
    List<Assignments> filtered = assignments
        .where((a) => a.user.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    if (sortByUser) {
      filtered.sort((a, b) => a.user.toLowerCase().compareTo(b.user.toLowerCase()));
    }

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        backgroundColor: myColors.secondary,
        title: Text(
          '${widget.costume.title} Assignments',
          style: TextStyle(
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
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              children: [
                Material(
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
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final assignment = filtered[index];
                return Column(
                  children: [
                    InkWell(
                      onTap: isAdmin
                        ? () => _addOrEditAssignment(existing: assignment, index: index)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${assignment.number} ${assignment.size}',
                            style: TextStyle(
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
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
