import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:raw_threads/classes/main_classes/assignments.dart';

class AssignmentProvider extends ChangeNotifier {
  final String adminId;

  String? _currentDanceId;
  String? _currentGender;
  String? _currentCostumeId;

  final List<Assignments> _assignments = [];
  List<Assignments> get assignments => List.unmodifiable(_assignments);

  AssignmentProvider({required this.adminId});

  /// Initialize context for a specific costume
  Future<void> setContext({
    required String danceId,
    required String gender,
    required String costumeId,
  }) async {
    // Only reload if context changes
    if (_currentDanceId == danceId &&
        _currentGender == gender &&
        _currentCostumeId == costumeId) return;

    _currentDanceId = danceId;
    _currentGender = gender;
    _currentCostumeId = costumeId;

    await _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    _assignments.clear();

    if (_currentDanceId == null ||
        _currentGender == null ||
        _currentCostumeId == null) {
      notifyListeners();
      return;
    }

    final path =
        'admins/$adminId/dances/$_currentDanceId/costumes/$_currentGender/$_currentCostumeId/assignments';

    try {
      final snapshot = await FirebaseDatabase.instance.ref(path).get();
      final data = snapshot.value;

      if (data != null && data is Map) {
        data.forEach((key, value) {
          try {
            final assignment = Assignments.fromJson(Map<String, dynamic>.from(value));
            _assignments.add(assignment);
          } catch (e) {
            if (kDebugMode) print('Error parsing assignment: $e');
          }
        });
      }
    } catch (e) {
      if (kDebugMode) print('Failed to load assignments: $e');
    }

    notifyListeners();
  }

  Future<void> addAssignment(Assignments assignment) async {
    if (_currentDanceId == null || _currentGender == null || _currentCostumeId == null) return;

    final path =
        'admins/$adminId/dances/$_currentDanceId/costumes/$_currentGender/$_currentCostumeId/assignments/${assignment.id}';
    await FirebaseDatabase.instance.ref(path).set(assignment.toJson());

    _assignments.add(assignment);
    notifyListeners();
  }

  Future<void> updateAssignment(Assignments assignment) async {
    if (_currentDanceId == null || _currentGender == null || _currentCostumeId == null) return;

    final path =
        'admins/$adminId/dances/$_currentDanceId/costumes/$_currentGender/$_currentCostumeId/assignments/${assignment.id}';
    await FirebaseDatabase.instance.ref(path).set(assignment.toJson());

    final index = _assignments.indexWhere((a) => a.id == assignment.id);
    if (index != -1) _assignments[index] = assignment;

    notifyListeners();
  }

  Future<void> deleteAssignment(String assignmentId) async {
    if (_currentDanceId == null || _currentGender == null || _currentCostumeId == null) return;

    final path =
        'admins/$adminId/dances/$_currentDanceId/costumes/$_currentGender/$_currentCostumeId/assignments/$assignmentId';
    await FirebaseDatabase.instance.ref(path).remove();

    _assignments.removeWhere((a) => a.id == assignmentId);
    notifyListeners();
  }
}
