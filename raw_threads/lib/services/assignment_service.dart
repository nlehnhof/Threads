import 'dart:convert';
import 'package:raw_threads/classes/main_classes/assignments.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AssignmentService {
  AssignmentService._privateConstructor();
  static final AssignmentService instance = AssignmentService._privateConstructor();

  List<Assignments> _cachedAssignments = [];
  List<Assignments> get assignments => List.unmodifiable(_cachedAssignments);

  /// Add a new assignment under the given admin, dance, gender, and costume
  Future<void> add(String adminId, String danceId, String gender, String costumeId, Assignments assignment) async {
    if (adminId.isEmpty || danceId.isEmpty || gender.isEmpty || costumeId.isEmpty) {
      print("❌ Cannot add assignment: adminId, danceId, gender, or costumeId is empty");
      return;
    }
    
    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender/$costumeId/assignments/${assignment.id}');

    await ref.set(assignment.toJson());

    final snapshot = await ref.get();
    print(snapshot.exists ? 'Verified assignment added' : 'Error adding assignment');
  }

  Future<void> load(String costumeId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('assignments_$costumeId');
    if (data == null) {
      _cachedAssignments = [];
      return;
    }

    final decoded = json.decode(data);
    _cachedAssignments = (decoded as List).map((item) => Assignments.fromJson(item)).toList();
  }

  Future<void> save(String costumeId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_cachedAssignments.map((a) => a.toJson()).toList());
    await prefs.setString('assignments_$costumeId', encoded);
  }

  /// Update an existing assignment
  Future<void> update(String adminId, String danceId, String gender, String costumeId, Assignments updatedAssignment) async {
    if (adminId.isEmpty) return;

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender/$costumeId/assignments/${updatedAssignment.id}');

    await ref.set(updatedAssignment.toJson());
  }

  /// Delete an assignment by id
  Future<void> delete(String adminId, String danceId, String gender, String costumeId, String assignmentId) async {
    if (adminId.isEmpty) return;

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender/$costumeId/assignments/$assignmentId');

    await ref.remove();
  }

  /// Listen to assignment changes for a costume
  Future<StreamSubscription?> listenToAssignments({
    required String adminId,
    required String danceId,
    required String gender,
    required String costumeId,
    required void Function(List<Assignments>) onUpdate,
  }) async {
    if (adminId.isEmpty) return null;

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender/$costumeId/assignments');

    return ref.onValue.listen((event) {
      final data = event.snapshot.value;

      if (data != null && data is Map) {
        final assignments = <Assignments>[];

        data.forEach((key, value) {
          final json = Map<String, dynamic>.from(value);
          json['id'] = key; // Set ID from key
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

  /// Helper: Find adminId by adminCode (for your app context provider)
  Future<String?> findAdminIdByAdminCode(String adminCode) async {
    final snap = await FirebaseDatabase.instance.ref('admins').orderByChild('admincode').equalTo(adminCode).get();
    if (snap.exists && snap.value is Map) {
      // Return the first matching adminId key
      final adminsMap = snap.value as Map;
      return adminsMap.keys.first;
    }
    return null;
  }
}
