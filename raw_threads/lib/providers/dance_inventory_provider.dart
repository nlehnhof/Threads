import 'package:flutter/foundation.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/services/auth_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DanceInventoryProvider extends ChangeNotifier {
  final List<Dances> _dances = [];
  List<Dances> get dances => List.unmodifiable(_dances);

  final Map<String, Dances> _danceMap = {};
  List<Dances> get allDances => _danceMap.values.toList();

  Dances ? getDanceById(String id) => _danceMap[id];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('inventory_dances');
    if (data != null) {
      final decoded = json.decode(data);
      _dances.clear();
      _dances.addAll((decoded as List).map((e) => Dances.fromJson(e)));

      _danceMap.clear();
      for (var dance in _dances) {
        _danceMap[dance.id] = dance;
      }

      notifyListeners();
    }
  }

  Future<void> add(Dances dance) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return;

    final ref = FirebaseDatabase.instance.ref('admins/$adminId/dances/${dance.id}');
    await ref.set(dance.toJson());

    _dances.add(dance);
    _danceMap[dance.id] = dance;
    await _saveLocally();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return;

    await FirebaseDatabase.instance.ref('admins/$adminId/dances/$id').remove();
    _dances.removeWhere((d) => d.id == id);
    _danceMap.remove(id);
    await _saveLocally();
    notifyListeners();
  }

  Future<void> update(Dances updated) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return;

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/${updated.id}');
    await ref.set(updated.toJson());

    final index = _dances.indexWhere((d) => d.id == updated.id);
    if (index != -1) {
      _dances[index] = updated;
    }

    _danceMap[updated.id] = updated;

    await _saveLocally();
    notifyListeners();
  }

  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'inventory_dances',
      json.encode(_dances.map((d) => d.toJson()).toList()),
    );
  }
}
