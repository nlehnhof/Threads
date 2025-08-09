import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/assignments.dart';
import 'package:raw_threads/services/assignment_service.dart'; // hypothetical service managing assignments
import 'dart:async';

class AssignmentProvider extends ChangeNotifier {
  String? _danceId;
  String? _gender;
  String? _costumeId;

  List<Assignments> _assignments = [];
  List<Assignments> get assignments => List.unmodifiable(_assignments);

  StreamSubscription<dynamic>? _subscription;

  AssignmentProvider();

  void updateContext({String? danceId, String? gender, String? costumeId}) {
    print('updateContext called');
    if (_danceId == danceId && _gender == gender && _costumeId == costumeId) {
      print('Context unchanged, returning early');
      return;
    }

    _danceId = danceId;
    _gender = gender;
    _costumeId = costumeId;

    _subscription?.cancel();
    _assignments = [];

    if (_danceId != null && _gender != null && _costumeId != null) {
      print('Initialize');
      _initialize();
    } else {
      print('One or more IDs are null');
      notifyListeners();
    }
  }

  Future<void> _initialize() async {
    if (_danceId == null || _gender == null || _costumeId == null) return;

    _subscription = await AssignmentService.instance.listenToAssignments(
      danceId: _danceId!,
      gender: _gender!,
      costumeId: _costumeId!,
      onUpdate: (updatedList) {
        _assignments = updatedList;
        notifyListeners();
      },
    );
  }

  Future<void> addAssignment(Assignments assignment) async {
    if (_danceId == null || _gender == null || _costumeId == null) return;
    await AssignmentService.instance.add(_danceId!, _gender!, _costumeId!, assignment);
  }

  Future<void> updateAssignment(Assignments assignment) async {
    if (_danceId == null || _gender == null || _costumeId == null) return;
    await AssignmentService.instance.update(_danceId!, _gender!, _costumeId!, assignment);
  }

  Future<void> deleteAssignment(Assignments assignment) async {
    if (_danceId == null || _gender == null || _costumeId == null) return;
    await AssignmentService.instance.delete(_danceId!, _gender!, _costumeId!, assignment.id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
