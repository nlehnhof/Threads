import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';

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

  Future<void> add(Dances newDance) async {
    _cachedDances.add(newDance);
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
    _cachedDances.removeWhere((d) => d.id == id);
    await save();
  }
}
