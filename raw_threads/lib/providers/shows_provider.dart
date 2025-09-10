import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../classes/main_classes/shows.dart';
import 'dance_inventory_provider.dart';
import '../pages/show_builds/dance_with_status.dart';
import 'dart:async';

class ShowsProvider extends ChangeNotifier {
  final String adminId;
  final DatabaseReference db = FirebaseDatabase.instance.ref();

  ShowsProvider({required this.adminId});

  final List<Shows> _shows = [];
  List<Shows> get shows => List.unmodifiable(_shows);

  // showId -> danceId -> DanceStatus
  final Map<String, Map<String, DanceStatus>> _danceStatuses = {};
  Map<String, DanceStatus> getDanceStatuses(String showId) =>
      _danceStatuses[showId] ?? {};

  bool _initialized = false; // Add to ShowsProvider

  Future<void> init(DanceInventoryProvider danceProvider) async {
    if (_initialized) return; // Prevent multiple initializations
    _initialized = true;

    try {
      // Clear previous data
      _shows.clear();
      _danceStatuses.clear();

      final snapshot = await db.child('admins/$adminId/shows').get();
      if (!snapshot.exists) {
        notifyListeners();
        return;
      }

      final rawData = snapshot.value as Map<dynamic, dynamic>;
      final data = rawData.map((key, value) => MapEntry(key.toString(), value));

      final List<Shows> loadedShows = [];
      final Map<String, Map<String, DanceStatus>> loadedStatuses = {};

      data.forEach((showId, showData) {
        final showJson = Map<String, dynamic>.from(showData as Map);
        final show = Shows.fromJson(showJson);

        // Prevent duplicate show IDs
        if (!loadedShows.any((s) => s.id == show.id)) {
          loadedShows.add(show);
        }

        final danceStatusMap = <String, DanceStatus>{};
        final rawStatuses = showJson['danceStatuses'];
        if (rawStatuses is Map) {
          rawStatuses.forEach((danceId, value) {
            final danceJson = value as Map;
            final dance = danceProvider.getDanceById(danceId.toString());
            if (dance != null) {
              danceStatusMap[danceId.toString()] = DanceStatus(
                dance: dance,
                status: danceJson['status']?.toString() ?? 'Not Ready',
              );
            }
          });
        }
        loadedStatuses[show.id] = danceStatusMap;
      });

      _shows.addAll(loadedShows);
      _danceStatuses.addAll(loadedStatuses);

      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ShowsProvider: $e');
    }
  }


  // Add a new show
  Future<void> addShow(Shows show) async {
    try {
      await db.child('admins/$adminId/shows/${show.id}').set(show.toJson());
      _shows.add(show);
      _danceStatuses[show.id] = {};
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to add show: $e');
    }
  }

  // Update existing show (does not overwrite dance statuses)
  Future<void> updateShow(Shows updatedShow) async {
    try {
      await db
          .child('admins/$adminId/shows/${updatedShow.id}')
          .update(updatedShow.toJson());

      final index = _shows.indexWhere((s) => s.id == updatedShow.id);
      if (index != -1) _shows[index] = updatedShow;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update show: $e');
    }
  }

  // Remove a show
  Future<void> removeShow(String showId) async {
    try {
      await db.child('admins/$adminId/shows/$showId').remove();
      _shows.removeWhere((s) => s.id == showId);
      _danceStatuses.remove(showId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to remove show: $e');
    }
  }

  // Update a single dance status
  Future<void> updateDanceStatus(
      String showId, String danceId, String status) async {
    try {
      await db
          .child('admins/$adminId/shows/$showId/danceStatuses/$danceId')
          .update({'status': status});

      _danceStatuses[showId] ??= {};
      _danceStatuses[showId]![danceId]?.status = status;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update dance status: $e');
    }
  }

  // Bulk update dance statuses
  Future<void> updateDanceStatuses(
      String showId, Map<String, String> statuses) async {
    try {
      final updates = {for (var e in statuses.entries) e.key: {'status': e.value}};
      await db.child('admins/$adminId/shows/$showId/danceStatuses').update(updates);

      _danceStatuses[showId] ??= {};
      statuses.forEach((danceId, status) {
        _danceStatuses[showId]![danceId]?.status = status;
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update dance statuses: $e');
    }
  }
}
