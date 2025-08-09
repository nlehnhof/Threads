import 'dart:convert';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
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
    if (danceId.isEmpty || gender.isEmpty) {
      print("❌ Cannot add assignment: danceId or gender is empty");
      return;
    } 
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return;
    print(danceId);
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
  }

  Future<void> delete(String danceId, String gender, String costumeId, String assignmentId) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return;

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender/$costumeId/assignments/$assignmentId');

    await ref.remove();
  }

  /// Find the path of an assignment by ID.
  /// Note: you must pass danceId, gender, and assignments list to this method, since they are needed.
  Future<Map<String, String>?> findAssignmentPath(
    String targetAssignmentId,
    CostumePiece costume,
    String danceId,
    String gender,
    List<Assignments> assignments,
  ) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return null;

    final costumeSnap = await FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender/')
        .get();

    final costumes = costumeSnap.value as Map?;

    if (costumes == null) return null;

    for (final costumeEntry in costumes.entries) {
      final costumeId = costumeEntry.key;
      final costumeData = costumeEntry.value;

      if (assignments.any((a) => a.id == targetAssignmentId)) {
        return {
          'costumeId': costumeId,
          'danceId': danceId,
          'gender': gender,
          'costumeData': costumeData,
        };
      }
    }
    return null;
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

    return ref.onValue.listen((event) {
      final data = event.snapshot.value;

      if (data != null && data is Map) {
        final assignments = <Assignments>[];

        data.forEach((key, value) {
          final json = Map<String, dynamic>.from(value);
          json['id'] = key;  // Set ID from key
          assignments.add(Assignments.fromJson(json));
        });

        _cachedAssignments = assignments;
        onUpdate(assignments);
      } else {
        _cachedAssignments = [];
        onUpdate([]);
      }
    });
  }
}
