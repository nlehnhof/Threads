import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../classes/main_classes/shows.dart';
import 'dance_inventory_provider.dart';
import '../pages/show_builds/dance_with_status.dart';

class ShowsProvider extends ChangeNotifier {
  final String adminId;
  final DatabaseReference db = FirebaseDatabase.instance.ref();

  final List<Shows> _shows = [];
  List<Shows> get shows => List.unmodifiable(_shows);

  // Map of showId -> danceId -> DanceStatus
  final Map<String, Map<String, DanceStatus>> _danceStatuses = {};
  Map<String, DanceStatus> getDanceStatuses(String showId) =>
      _danceStatuses[showId] ?? {};

  bool _initialized = false;
  bool get isInitialized => _initialized;

  ShowsProvider({required this.adminId});

  /// Initialize the provider with optional DanceInventoryProvider
  Future<void> init([DanceInventoryProvider? danceProvider]) async {
    if (_initialized) return;

    try {
      final snapshot = await db.child('admins/$adminId/shows').get();
      _shows.clear();
      _danceStatuses.clear();

      if (snapshot.exists) {
        final rawData = Map<String, dynamic>.from(snapshot.value as Map);
        for (var entry in rawData.entries) {
          final showData = Map<String, dynamic>.from(entry.value);
          final show = Shows.fromJson(showData);
          _shows.add(show);

          final danceStatusMap = <String, DanceStatus>{};
          final rawStatuses = showData['danceStatuses'] as Map?;
          if (rawStatuses != null && danceProvider != null) {
            rawStatuses.forEach((danceId, value) {
              final dance = danceProvider.getDanceById(danceId.toString());
              if (dance != null && value is Map) {
                danceStatusMap[danceId.toString()] = DanceStatus(
                  dance: dance,
                  status: value['status']?.toString() ?? 'Not Ready',
                );
              }
            });
          }

          _danceStatuses[show.id] = danceStatusMap;
        }
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize ShowsProvider: $e');
    }
  }

  /// Reset provider (useful for logout or re-initialization)
  Future<void> reset() async {
    _shows.clear();
    _danceStatuses.clear();
    _initialized = false;
    notifyListeners();
  }

  // --- CRUD METHODS ---

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
