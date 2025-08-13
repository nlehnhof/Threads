import 'package:flutter/foundation.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class DanceInventoryProvider extends ChangeNotifier {
  final String adminId;
  final List<Dances> _dances = [];
  List<Dances> get dances => List.unmodifiable(_dances);

  final Map<String, Dances> _danceMap = {};
  List<Dances> get allDances => _danceMap.values.toList();

  Dances? getDanceById(String id) => _danceMap[id];

  StreamSubscription<DatabaseEvent>? _dancesSubscription;
  
  DanceInventoryProvider({
    required this.adminId,
  });

  Future<void> init() async {
    // Cancel any existing subscription first
    await _dancesSubscription?.cancel();

    // Load initial data once
    await _loadFromFirebase();

    // Set up listener for live updates
    _dancesSubscription = FirebaseDatabase.instance
      .ref('admins/$adminId/dances')
      .onValue
      .listen((event) {
        final dancesMap = event.snapshot.value as Map<dynamic, dynamic>?;

        _dances.clear();
        _danceMap.clear();

        if (dancesMap != null) {
          dancesMap.forEach((key, value) {
            final dance = Dances.fromJson(Map<String, dynamic>.from(value));
            _dances.add(dance);
            _danceMap[key] = dance;
          });
        }
        notifyListeners();
      });
  }

  Future<void> _loadFromFirebase() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('admins/$adminId/dances')
        .get();

    if (snapshot.exists) {
      final dancesMap = Map<String, dynamic>.from(snapshot.value as Map);
      _dances.clear();
      _danceMap.clear();

      dancesMap.forEach((key, value) {
        final dance = Dances.fromJson(Map<String, dynamic>.from(value));
        _dances.add(dance);
        _danceMap[key] = dance;
      });

      notifyListeners();
    }
  }

  Future<void> loadForAdmin() async {
    _dancesSubscription?.cancel();

    final snapshot = await FirebaseDatabase.instance
        .ref('admins/$adminId/dances')
        .get();

    if (snapshot.exists) {
      final dancesMap = Map<String, dynamic>.from(snapshot.value as Map);
      _dances.clear();
      _dances.addAll(dancesMap.entries
          .map((e) => Dances.fromJson(Map<String, dynamic>.from(e.value))));
      
      _danceMap.clear();
      for (var dance in _dances) {
        _danceMap[dance.id] = dance;
      }
      notifyListeners();
    } else {
      _dances.clear();
      _danceMap.clear();
      notifyListeners();
    }

    _dancesSubscription = FirebaseDatabase.instance
        .ref('admins/$adminId/dances')
        .onValue
        .listen((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;

          if (data != null) {
            _dances.clear();
            _dances.addAll(data.entries
                .map((e) => Dances.fromJson(Map<String, dynamic>.from(e.value))));
            
            _danceMap.clear();
            for (var dance in _dances) {
              _danceMap[dance.id] = dance;
            }
          } else {
            _dances.clear();
            _danceMap.clear();
          }
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _dancesSubscription?.cancel();
    super.dispose();
  }


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
    // final adminId = await authService.value.getEffectiveAdminId();
    // if (adminId == null) return;

    final ref = FirebaseDatabase.instance.ref('admins/$adminId/dances/${dance.id}');
    await ref.set(dance.toJson());
  }

  Future<void> delete(String id) async {
    // final adminId = await authService.value.getEffectiveAdminId();
    // if (adminId == null) return;

    await FirebaseDatabase.instance.ref('admins/$adminId/dances/$id').remove();
    _dances.removeWhere((d) => d.id == id);
    _danceMap.remove(id);
    await _saveLocally();
    notifyListeners();
  }

  Future<void> update(Dances updated) async {
    final ref = FirebaseDatabase.instance.ref('admins/$adminId/dances/${updated.id}');
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
