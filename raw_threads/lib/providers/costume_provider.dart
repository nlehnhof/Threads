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

  /// Initialize with danceId and gender (can be called multiple times
  /// to switch the context to a new dance/gender).
  Future<void> init({required String danceId, required String gender}) async {
    if (_initialized && _currentDanceId == danceId && _currentGender == gender) return; 
    
    _initialized = false;
    notifyListeners();

    await setDanceAndGender(danceId, gender);

    _initialized = true;
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
    notifyListeners();

    _costumesSubscription = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      _costumes.clear();

      if (data != null && data is Map) {
        data.forEach((key, value) {
          try {
            final costume = CostumePiece.fromJson(Map<String, dynamic>.from(value));
            _costumes.add(costume);
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing costume: $e');
            }
          }
        });
      }
      notifyListeners();
    });
  }

  Future<Map<String, String>?> findCostumePath(String costumeId, String adminId) async {
    final db = FirebaseDatabase.instance.ref('admins/$adminId/dances');

    final snapshot = await db.get();
    if (!snapshot.exists) return null;

    final dancesData = snapshot.value;
    if (dancesData == null || dancesData is! Map) return null;

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
              // Found the costume
              return {'danceId': danceId, 'gender': gender};
            }
          }
        }
      }
    }
    return null; // Not found
  }

  Future<void> addCostume(CostumePiece costume) async {
    if (_currentDanceId == null || _currentGender == null) {
      throw Exception('Dance ID and Gender must be set before adding costumes.');
    }

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$_currentDanceId/costumes/$_currentGender/${costume.id}');

    await ref.set(costume.toJson());
    // _costumes.add(costume);
    notifyListeners();
  }

  Future<void> updateCostume(CostumePiece costume) async {
    if (_currentDanceId == null || _currentGender == null) {
      throw Exception('Dance ID and Gender must be set before updating costumes.');
    }

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$_currentDanceId/costumes/$_currentGender/${costume.id}');

    await ref.set(costume.toJson());

    // final index = _costumes.indexWhere((c) => c.id == costume.id);
    // if (index != -1) {
    //   _costumes[index] = costume;
    //   notifyListeners();
    // }
  }

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

  /// Optionally provide a getter to current danceId and gender if needed
  String? get currentDanceId => _currentDanceId;
  String? get currentGender => _currentGender;

  @override
  void dispose() {
    _costumesSubscription?.cancel();
    super.dispose();
  }
}
