import 'dart:convert';
import 'package:raw_threads/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class DanceInventoryService {
  DanceInventoryService._privateConstructor();
  static final DanceInventoryService instance = DanceInventoryService._privateConstructor();
  static const _key = 'inventory_dances';

  List<Dances> _cachedDances = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) {
      _cachedDances = [];
      return;
    }
    final decoded = json.decode(data);
    _cachedDances = (decoded as List)
        .map((item) => Dances.fromJson(item))
        .toList();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_cachedDances.map((d) => d.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  List<Dances> get dances => List.unmodifiable(_cachedDances);

  Dances? getById(String id) {
    try {
      return _cachedDances.firstWhere((dance) => dance.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(Dances dance) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return;
    if (_cachedDances.any((d) => d.id == dance.id)) return;

    final ref = FirebaseDatabase.instance
        .ref()
        .child('admins')
        .child(adminId)
        .child('dances')
        .child(dance.id); // Assume `dance.id` is already unique (UUID)

    await ref.set(dance.toJson());

    // Optional: update local list (if keeping cache)
    _cachedDances.add(dance);
    await save();
  }

  Future<void> update(Dances updatedDance) async {
    final index = _cachedDances.indexWhere((d) => d.id == updatedDance.id);
    if (index != -1) {
      _cachedDances[index] = updatedDance;
      await save();
    }
  }

  Future<void> delete(String id) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return;

    await FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$id')
        .remove();

    _cachedDances.removeWhere((dance) => dance.id == id);
    await save();
  }

  Future<StreamSubscription?> listenToDance(String danceId, void Function(Dances) onUpdate) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return null;

    final ref = FirebaseDatabase.instance
        .ref()
        .child('admins')
        .child(adminId)
        .child('dances')
        .child(danceId);

    return ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        onUpdate(Dances.fromJson(Map<String, dynamic>.from(data)));
      }
    });
  }
}
