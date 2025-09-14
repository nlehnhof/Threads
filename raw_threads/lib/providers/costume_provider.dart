import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';

class CostumesProvider extends ChangeNotifier {
  final String adminId;

  String? _currentDanceId;
  String? _currentGender;

  bool _initialized = false;
  bool get initialized => _initialized;

  final List<CostumePiece> _costumes = [];
  List<CostumePiece> get costumes => List.unmodifiable(_costumes);

  StreamSubscription<DatabaseEvent>? _costumesSubscription;

  CostumesProvider({required this.adminId});

  /// Initialize with danceId and gender
  Future<void> init({required String danceId, required String gender}) async {
    if (_initialized && _currentDanceId == danceId && _currentGender == gender) return;

    await setDanceAndGender(danceId, gender);

    _initialized = true; // set initialized only after listener is ready
    notifyListeners();
  }

  /// Set or update the current dance and gender.
  /// Cancels old subscription and creates new listener on Firebase.
  Future<void> setDanceAndGender(String danceId, String gender) async {
    if (_currentDanceId == danceId && _currentGender == gender) return;

    _currentDanceId = danceId;
    _currentGender = gender;

    // Cancel previous subscription if any
    await _costumesSubscription?.cancel();

    _costumes.clear();
    notifyListeners(); // optional: notify immediately for UI reset

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender');

    _costumesSubscription = ref.onValue.listen((event) {
      _costumes.clear();

      final data = event.snapshot.value;
      if (data != null && data is Map) {
        data.forEach((key, value) {
          try {
            final map = Map<String, dynamic>.from(value);
            map['id'] = key;
            final costume = CostumePiece.fromJson(map);
            _costumes.add(costume);
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing costume: $e');
            }
          }
        });
      }

      // Notify listeners **once per update**
      Future.microtask(() => notifyListeners());
    });
  }

  /// Lookup costume by ID across all dances/genders
  Future<Map<String, String>?> findCostumePath(String costumeId) async {
    final db = FirebaseDatabase.instance.ref('admins/$adminId/dances');
    final snapshot = await db.get();
    if (!snapshot.exists || snapshot.value == null) return null;

    final dancesData = snapshot.value;
    if (dancesData is! Map) return null;

    for (final danceEntry in dancesData.entries) {
      final danceId = danceEntry.key;
      final danceValue = danceEntry.value;
      if (danceValue is Map && danceValue.containsKey('costumes')) {
        final costumesMap = danceValue['costumes'];
        if (costumesMap is Map) {
          for (final genderEntry in costumesMap.entries) {
            final gender = genderEntry.key;
            final genderCostumes = genderEntry.value;
            if (genderCostumes is Map && genderCostumes.containsKey(costumeId)) {
              return {'danceId': danceId, 'gender': gender};
            }
          }
        }
      }
    }
    return null;
  }

  /// Add a new costume
  Future<void> addCostume(CostumePiece costume) async {
    if (_currentDanceId == null || _currentGender == null) {
      throw Exception('Dance ID and Gender must be set before adding costumes.');
    }

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$_currentDanceId/costumes/$_currentGender/${costume.id}');

    await ref.set(costume.toJson());
    // The listener will automatically update _costumes
  }

  /// Update an existing costume
  Future<void> updateCostume(CostumePiece costume) async {
    if (_currentDanceId == null || _currentGender == null) {
      throw Exception('Dance ID and Gender must be set before updating costumes.');
    }

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$_currentDanceId/costumes/$_currentGender/${costume.id}');

    await ref.set(costume.toJson());
  }

  /// Delete a costume
  Future<void> deleteCostume(String costumeId) async {
    if (_currentDanceId == null || _currentGender == null) {
      throw Exception('Dance ID and Gender must be set before deleting costumes.');
    }

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$_currentDanceId/costumes/$_currentGender/$costumeId');

    await ref.remove();
    _costumes.removeWhere((c) => c.id == costumeId);
    notifyListeners();
  }

  /// Get costume by ID in current list
  CostumePiece? getCostumeById(String costumeId) =>
      _costumes.firstWhereOrNull((c) => c.id == costumeId);

  /// Get costume title
  String? getCostumeNameById(String costumeId) => getCostumeById(costumeId)?.title;

  String? get currentDanceId => _currentDanceId;
  String? get currentGender => _currentGender;

  @override
  void dispose() {
    _costumesSubscription?.cancel();
    super.dispose();
  }
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
