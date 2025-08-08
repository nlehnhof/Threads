import 'dart:convert';
import 'package:raw_threads/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raw_threads/classes/main_classes/assignments.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class AssignmentService {
  AssignmentService._privateConstructor();
  static final AssignmentService instance = AssignmentService._privateConstructor();

  List<Assignments> _cachedAssignments = [];
  List<Assignments> get assignments => List.unmodifiable(_cachedAssignments);

  Future<void> add(String danceId, String gender, String costumeId, Assignments assignment) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return;

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender/$costumeId/assignments/${assignment.id}');

    await ref.set(assignment.toJson());

    final snapshot = await ref.get();
    print(snapshot.exists ? 'Verified' : 'Error');
  }

  Future<void> load(String costumeId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('assignments_$costumeId');
    if (data == null) {
      _cachedAssignments = [];
      return;
    }

    final decoded = json.decode(data);
    _cachedAssignments = (decoded as List)
        .map((item) => Assignments.fromJson(item))
        .toList();
  }

  Future<void> save(String costumeId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_cachedAssignments.map((a) => a.toJson()).toList());
    await prefs.setString('assignments_$costumeId', encoded);
  }


  Future<void> update(String danceId, String gender, String costumeId, Assignments updatedAssignment) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return;

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender/$costumeId/assignments/${updatedAssignment.id}');

    await ref.set(updatedAssignment.toJson());
    // Do NOT update _cachedCostumes here.
  }

  Assignments? getById(String id) {
    try {
      return _cachedAssignments.firstWhere((assignments) => assignments.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String danceId, String gender, String costumeId, String assignmentId) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return;

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender/$costumeId/assignments/$assignmentId');

    await ref.remove();
  }

  Future<StreamSubscription?> listenToAssignments({
    required String danceId,
    required String gender,
    required String costumeId,
    required void Function(List<Assignments>) onUpdate,
  }) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return null;

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender/$costumeId/assignments');

    return ref.onValue.listen((event) async {
      final data = event.snapshot.value;

      if (data is Map) {
        final assignments = data.entries.map((entry) {
          final json = Map<String, dynamic>.from(entry.value);
          return Assignments.fromJson(json);
        }).toList();

        _cachedAssignments = assignments;
        await save(costumeId);
        onUpdate(assignments);
      } else {
        _cachedAssignments = [];
        await save(costumeId);
        onUpdate([]);
      }
    });
  }
}
