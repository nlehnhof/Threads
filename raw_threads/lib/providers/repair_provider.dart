import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:raw_threads/classes/main_classes/repairs.dart';
import 'package:raw_threads/classes/main_classes/issues.dart';

class RepairProvider extends ChangeNotifier {
  final String adminId;

  final List<Repairs> _repairs = [];
  final Map<String, Repairs> _repairMap = {};

  List<Repairs> get repairs => List.unmodifiable(_repairs);
  Repairs? getRepairById(String id) => _repairMap[id];

  StreamSubscription<DatabaseEvent>? _repairSubscription;

  RepairProvider({required this.adminId});

  Future<void> init() async {
    await _repairSubscription?.cancel();
    await _loadFromFirebase();

    // Listen for live updates
    _repairSubscription = FirebaseDatabase.instance
        .ref('admins/$adminId/repairs')
        .onValue
        .listen((event) {
      final repairsMap = event.snapshot.value as Map<dynamic, dynamic>?;

      _repairs.clear();
      _repairMap.clear();

      if (repairsMap != null) {
        repairsMap.forEach((key, value) {
          final repair = Repairs.fromJson(Map<String, dynamic>.from(value));
          _repairs.add(repair);
          _repairMap[repair.id] = repair;
        });
      }
      notifyListeners();
    });
  }

  Future<void> _loadFromFirebase() async {
    final snapshot =
        await FirebaseDatabase.instance.ref('admins/$adminId/repairs').get();

    _repairs.clear();
    _repairMap.clear();

    if (snapshot.exists) {
      final repairMap = Map<String, dynamic>.from(snapshot.value as Map);
      repairMap.forEach((key, value) {
        final repair = Repairs.fromJson(Map<String, dynamic>.from(value));
        _repairs.add(repair);
        _repairMap[repair.id] = repair;
      });
    }
    notifyListeners();
  }

  Future<void> add(Repairs repair) async {
    final ref =
        FirebaseDatabase.instance.ref('admins/$adminId/repairs/${repair.id}');
    await ref.set(repair.toJson());
  }

  Future<void> update(Repairs updated) async {
    final ref =
        FirebaseDatabase.instance.ref('admins/$adminId/repairs/${updated.id}');
    await ref.set(updated.toJson());

    final index = _repairs.indexWhere((r) => r.id == updated.id);
    if (index != -1) _repairs[index] = updated;
    _repairMap[updated.id] = updated;

    await _saveLocally();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await FirebaseDatabase.instance.ref('admins/$adminId/repairs/$id').remove();
    _repairs.removeWhere((r) => r.id == id);
    _repairMap.remove(id);
    await _saveLocally();
    notifyListeners();
  }

  Future<void> markRepairCompleted(String repairId) async {
    final repair = _repairMap[repairId];
    if (repair == null) return;

    repair.completed = true;
    await update(repair);
  }

  Future<void> addIssueToRepair(String repairId, Issues newIssue) async {
    final repair = _repairMap[repairId];
    if (repair == null) return;

    repair.issues.add(newIssue);
    await update(repair);
  }

  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'repairs_$adminId',
      json.encode(_repairs.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('repairs_$adminId');
    if (data != null) {
      final decoded = json.decode(data) as List<dynamic>;
      _repairs.clear();
      _repairs.addAll(decoded.map((e) => Repairs.fromJson(e)));

      _repairMap.clear();
      for (var repair in _repairs) {
        _repairMap[repair.id] = repair;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _repairSubscription?.cancel();
    super.dispose();
  }
}
