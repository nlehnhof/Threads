import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';

class DanceInventoryProvider extends ChangeNotifier {
  final String adminId;

  final List<Dances> _dances = [];
  List<Dances> get dances => List.unmodifiable(_dances);

  final Map<String, Dances> _danceMap = {};
  List<Dances> get allDances => _danceMap.values.toList();

  Dances? getDanceById(String id) => _danceMap[id];

  StreamSubscription<DatabaseEvent>? _dancesSubscription;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  DanceInventoryProvider({required this.adminId});

  /// Initialize provider: load from Firebase and listen for updates
  Future<void> init() async {
    if (_initialized) return;

    // Cancel any previous subscription
    await _dancesSubscription?.cancel();

    // Load initial data
    await _loadFromFirebase();

    // Listen for real-time updates
    _dancesSubscription = FirebaseDatabase.instance
        .ref('admins/$adminId/dances')
        .onValue
        .listen((event) {
      final dancesMap = event.snapshot.value as Map<dynamic, dynamic>?;

      _dances.clear();
      _danceMap.clear();

      if (dancesMap != null) {
        dancesMap.forEach((key, value) {
          if (value is Map) {
            final dance = Dances.fromJson(Map<String, dynamic>.from(value));
            _dances.add(dance);
            _danceMap[key.toString()] = dance;
          }
        });
      }

      notifyListeners();
    });

    _initialized = true;
    notifyListeners();
  }

  /// Reset provider (useful on logout)
  Future<void> reset() async {
    _dances.clear();
    _danceMap.clear();
    await _dancesSubscription?.cancel();
    _initialized = false;
    notifyListeners();
  }

  /// Load dances once from Firebase
  Future<void> _loadFromFirebase() async {
    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('admins/$adminId/dances').get();

      _dances.clear();
      _danceMap.clear();

      if (snapshot.exists) {
        final dancesMap = Map<String, dynamic>.from(snapshot.value as Map);
        dancesMap.forEach((key, value) {
          if (value is Map) {
            final dance = Dances.fromJson(Map<String, dynamic>.from(value));
            _dances.add(dance);
            _danceMap[key] = dance;
          }
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load dances from Firebase: $e');
    }
  }

  /// Load cached dances from SharedPreferences
  Future<void> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('inventory_dances');
    if (data != null) {
      try {
        final decoded = json.decode(data) as List;
        _dances.clear();
        _dances.addAll(decoded.map((e) => Dances.fromJson(e)));

        _danceMap.clear();
        for (var dance in _dances) {
          _danceMap[dance.id] = dance;
        }

        notifyListeners();
      } catch (e) {
        debugPrint('Failed to load cached dances: $e');
      }
    }
  }

  /// Add a new dance
  Future<void> add(Dances dance) async {
    try {
      final ref =
          FirebaseDatabase.instance.ref('admins/$adminId/dances/${dance.id}');
      await ref.set(dance.toJson());

      _dances.add(dance);
      _danceMap[dance.id] = dance;

      await _saveLocally();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to add dance: $e');
    }
  }

  /// Delete a dance
  Future<void> delete(String id) async {
    try {
      await FirebaseDatabase.instance.ref('admins/$adminId/dances/$id').remove();
      _dances.removeWhere((d) => d.id == id);
      _danceMap.remove(id);

      await _saveLocally();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to delete dance: $e');
    }
  }

  /// Update an existing dance
  Future<void> update(Dances updated) async {
    try {
      final ref =
          FirebaseDatabase.instance.ref('admins/$adminId/dances/${updated.id}');
      await ref.set(updated.toJson());

      final index = _dances.indexWhere((d) => d.id == updated.id);
      if (index != -1) {
        _dances[index] = updated;
      }
      _danceMap[updated.id] = updated;

      await _saveLocally();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update dance: $e');
    }
  }

  /// Save dances locally to SharedPreferences
  Future<void> _saveLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'inventory_dances',
        json.encode(_dances.map((d) => d.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Failed to save dances locally: $e');
    }
  }

  @override
  void dispose() {
    _dancesSubscription?.cancel();
    super.dispose();
  }
}
