import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:raw_threads/classes/main_classes/shows.dart';

class ShowsProvider extends ChangeNotifier {
  final String adminId;
  final List<Shows> _shows = [];
  List<Shows> get shows => List.unmodifiable(_shows);

  StreamSubscription<DatabaseEvent>? _showsSubscription;

  ShowsProvider({
    required this.adminId,
  });

  // Initialize and start listening for changes for the given adminId
  Future<void> init() async {
    // Cancel existing subscription if any
    await _showsSubscription?.cancel();

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

    final snapshot = await FirebaseDatabase.instance
        .ref('admins/$adminId/shows')
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
    // Avoid duplicate IDs
    if (_shows.any((s) => s.id == show.id)) return;

    _shows.add(show);
    notifyListeners();

    await FirebaseDatabase.instance
        .ref('admins/$adminId/shows/${show.id}')
        .set(show.toJson());
  }

  Future<void> updateShow(Shows updatedShow) async {
    final index = _shows.indexWhere((s) => s.id == updatedShow.id);
    if (index != -1) {
      _shows[index] = updatedShow;
      notifyListeners();

      await FirebaseDatabase.instance
          .ref('admins/$adminId/shows/${updatedShow.id}')
          .set(updatedShow.toJson());
    }
  }

  Future<void> removeShow(String showId) async {
    
    Shows? removed = _shows.cast<Shows?>().firstWhere(
      (s) => s?.id == showId,
      orElse: () => null,
    );
    if (removed == null) return;

    _shows.removeWhere((s) => s.id == showId);
    notifyListeners();

    await FirebaseDatabase.instance
        .ref('admins/$adminId/shows/$showId')
        .remove();
  }

  @override
  void dispose() {
    _showsSubscription?.cancel();
    super.dispose();
  }
}
