import 'dart:async';
import 'package:flutter/material.dart';
import 'package:raw_threads/services/assignment_service.dart';
import 'package:raw_threads/classes/main_classes/assignments.dart';

class AssignmentsProvider extends ChangeNotifier {
  final String danceId;
  final String gender;
  final String costumeId;

  List<Assignments> _assignments = [];
  List<Assignments> get assignments => List.unmodifiable(_assignments);
  StreamSubscription<dynamic>? _subscription;

  AssignmentsProvider({
    // super.key,
    required this.danceId,
    required this.gender,
    required this.costumeId,
  }) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Start listening to Firebase changes
    _subscription = await AssignmentService.instance.listenToAssignments(
      danceId: danceId,
      gender: gender,
      costumeId: costumeId,
      onUpdate: (updatedList) {
        _assignments = updatedList;
        notifyListeners();
      },
    );
  }

  Future<void> addAssignment(Assignments assignments) async {
    await AssignmentService.instance.add(danceId, gender, costumeId, assignments);
    // The listener will automatically update the local list.
  }

  Future<void> updateAssignment(Assignments assignments) async {
    await AssignmentService.instance.update(danceId, gender, costumeId, assignments);
  }

  Future<void> deleteAssignment(String costumeId, String assignmentId) async {
    await AssignmentService.instance.delete(danceId, gender, costumeId, assignmentId);
  }

  Future<void> loadAssignments(Assignments assignments) async {
    await AssignmentService.instance.load(costumeId);
  }

  @override
  void dispose() {
    _subscription?.cancel(); // Clean up listener
    super.dispose();
  }
}
