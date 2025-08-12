import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // For accessing AppContextProvider
import 'package:raw_threads/classes/main_classes/assignments.dart';
import 'package:raw_threads/services/assignment_service.dart';
import 'package:raw_threads/providers/app_context_provider.dart'; // Your context provider

class AssignmentProvider extends ChangeNotifier {
  String? _adminId;
  String? _danceId;
  String? _gender;
  String? _costumeId;

  List<Assignments> _assignments = [];
  List<Assignments> get assignments => List.unmodifiable(_assignments);

  StreamSubscription<dynamic>? _subscription;

  AssignmentProvider();

  /// This method expects the BuildContext to access AppContextProvider for adminCode/adminId
  Future<void> updateContextWithContext(
    BuildContext context, {
    String? danceId,
    String? gender,
    String? costumeId,
  }) async {
    final appContext = Provider.of<AppContextProvider>(context, listen: false);

    // Resolve adminId from adminCode if needed
    if (appContext.adminId == null && appContext.adminCode != null) {
      final resolvedAdminId = await _resolveAdminIdFromCode(appContext.adminCode!);
      if (resolvedAdminId != null) {
        appContext.setAdminId(resolvedAdminId);
        _adminId = resolvedAdminId;
      } else {
        // Could not resolve adminId, handle accordingly (e.g., show error, clear context)
        print("⚠️ Warning: Could not resolve adminId from adminCode: ${appContext.adminCode}");
        _adminId = null;
      }
    } else {
      _adminId = appContext.adminId;
    }

    _danceId = danceId;
    _gender = gender;
    _costumeId = costumeId;

    // Cancel any previous subscriptions
    _subscription?.cancel();
    _assignments = [];

    if (_adminId != null && _danceId != null && _gender != null && _costumeId != null) {
      await _initialize();
    } else {
      notifyListeners();
    }
  }

  Future<String?> _resolveAdminIdFromCode(String adminCode) async {
    // Look up adminId in Firebase using adminCode
    return await AssignmentService.instance.findAdminIdByAdminCode(adminCode);
  }

  Future<void> _initialize() async {
    if (_adminId == null || _danceId == null || _gender == null || _costumeId == null) return;

    _subscription = await AssignmentService.instance.listenToAssignments(
      adminId: _adminId!,
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
    if (_adminId == null || _danceId == null || _gender == null || _costumeId == null) return;
    await AssignmentService.instance.add(_adminId!, _danceId!, _gender!, _costumeId!, assignment);
  }

  Future<void> updateAssignment(Assignments assignment) async {
    if (_adminId == null || _danceId == null || _gender == null || _costumeId == null) return;
    await AssignmentService.instance.update(_adminId!, _danceId!, _gender!, _costumeId!, assignment);
  }

  Future<void> deleteAssignment(Assignments assignment) async {
    if (_adminId == null || _danceId == null || _gender == null || _costumeId == null) return;
    await AssignmentService.instance.delete(_adminId!, _danceId!, _gender!, _costumeId!, assignment.id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
