import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:raw_threads/classes/main_classes/shows.dart';

class ShowsProvider extends ChangeNotifier {
  final List<Shows> _shows = [];
  List<Shows> get shows => List.unmodifiable(_shows);

  StreamSubscription<DatabaseEvent>? _showsSubscription;
  String? _adminId;

  // Initialize and start listening for changes for the given adminId
  Future<void> init(String adminId) async {
    // Cancel existing subscription if any
    await _showsSubscription?.cancel();

    _adminId = adminId;

    await load();

    // Load initial shows from Firebase once
    _showsSubscription = FirebaseDatabase.instance
        .ref('admins/$adminId/shows')
        .onValue
        .listen((event) {
          final showsMap = event.snapshot.value as Map<dynamic, dynamic>?;
        
          if (showsMap != null) {
            _shows.clear();
            _shows.addAll(showsMap.entries
            .map((e) => Shows.fromJson(Map<String, dynamic>.from(e.value))));
          } else {
            _shows.clear();
          }
          notifyListeners();
        });
  }
  
  Future<void> load() async {
    if (_adminId == null) return;

    final snapshot = await FirebaseDatabase.instance
        .ref('admins/$_adminId/shows')
        .get();

    if (snapshot.exists) {
      final showsMap = Map<String, dynamic>.from(snapshot.value as Map);
      _shows.clear();
      _shows.addAll(showsMap.entries
          .map((e) => Shows.fromJson(Map<String, dynamic>.from(e.value))));
    } else {
      _shows.clear();
    }
    notifyListeners();
  }

  Future<void> addShow(Shows show) async {
    if (_adminId == null) return;

    // Avoid duplicate IDs
    if (_shows.any((s) => s.id == show.id)) return;

    _shows.add(show);
    notifyListeners();

    await FirebaseDatabase.instance
        .ref('admins/$_adminId/shows/${show.id}')
        .set(show.toJson());
  }

  Future<void> updateShow(Shows updatedShow) async {
    if (_adminId == null) return;

    final index = _shows.indexWhere((s) => s.id == updatedShow.id);
    if (index != -1) {
      _shows[index] = updatedShow;
      notifyListeners();

      await FirebaseDatabase.instance
          .ref('admins/$_adminId/shows/${updatedShow.id}')
          .set(updatedShow.toJson());
    }
  }

  Future<void> removeShow(String showId) async {
    if (_adminId == null) return;

    Shows? removed = _shows.cast<Shows?>().firstWhere(
      (s) => s?.id == showId,
      orElse: () => null,
    );
    if (removed == null) return;

    _shows.removeWhere((s) => s.id == showId);
    notifyListeners();

    await FirebaseDatabase.instance
        .ref('admins/$_adminId/shows/$showId')
        .remove();
  }

  @override
  void dispose() {
    _showsSubscription?.cancel();
    super.dispose();
  }
}
