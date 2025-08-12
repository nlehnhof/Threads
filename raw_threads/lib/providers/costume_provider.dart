import 'dart:async';
import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

class CostumesProvider extends ChangeNotifier {
  String? _adminId;
  String? _danceId;
  String? _gender;

  final List<CostumePiece> _costumes = [];
  List<CostumePiece> get costumes => List.unmodifiable(_costumes);

  StreamSubscription<DatabaseEvent>? _costumesSubscription;
  CostumesProvider();

  Future<void> init({
    required String adminId,
    required String danceId,
    required String gender,
  }) async {
    print("CostumesProvider init called with adminId=$adminId, danceId=$danceId, gender=$gender");
    if (_adminId == adminId && _danceId == danceId && _gender == gender) return;
  
    _adminId = adminId;
    _danceId = danceId;
    _gender = gender;

    await _costumesSubscription?.cancel();
    _costumes.clear();
    notifyListeners();

    await _loadFromFirebase();

    _costumesSubscription = FirebaseDatabase.instance
        .ref('admins/$_adminId/dances/$_danceId/costumes/$_gender')
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
                print('error: $e');
              }
            });
          }
          notifyListeners();
        });
  }

  Future<void> _loadFromFirebase() async {
    if (_adminId == null || _danceId == null || _gender == null) return;

    final snapshot = await FirebaseDatabase.instance
        .ref('admins/$_adminId/dances/$_danceId/costumes/$_gender')
        .get();

    _costumes.clear();

    if (snapshot.exists) {
      final data = snapshot.value;
      if (data != null && data is Map) {
        data.forEach((key, value) {
          try {
            final costume = CostumePiece.fromJson(Map<String, dynamic>.from(value));
            _costumes.add(costume);
          } catch (e) {
            // ignore
          }
        });
      }
    }
    notifyListeners();
  }

  Future<void> addCostume(CostumePiece costume) async {
    if (_adminId == null || _danceId == null || _gender == null) {
      print("❌ Missing adminId, danceId, or gender; cannot add costume.");
      return;
    }

    print("Adding costume ${costume.id} to admins/$_adminId/dances/$_danceId/costumes/$_gender");

    final ref = FirebaseDatabase.instance
        .ref('admins/$_adminId/dances/$_danceId/costumes/$_gender/${costume.id}');

    try {
      await ref.set(costume.toJson());
      _costumes.add(costume);
      notifyListeners();
      print("✅ Costume added successfully.");
    } catch (e) {
      print("❌ Failed to add costume: $e");
    }
    notifyListeners();
  }

  Future<void> updateCostume(CostumePiece costume) async {
    if (_adminId == null || _danceId == null || _gender == null) return;
  
    final ref = FirebaseDatabase.instance
        .ref('admins/$_adminId/dances/$_danceId/costumes/$_gender/${costume.id}');

    await ref.set(costume.toJson());

    final index = _costumes.indexWhere((c) => c.id == costume.id);
    if (index != -1) {
      _costumes[index] = costume;
      notifyListeners();
    }
  }

  Future<Map<String, String>?> findCostumePath(String costumeId) async {
    if (_adminId == null || _adminId!.isEmpty) {
      print("Admin Id is null or empty. Cannot find costume path.");
      return null;
    }

    final dancesRef = FirebaseDatabase.instance.ref('admins/$_adminId/dances');
    final dancesSnap = await dancesRef.get();

    if (!dancesSnap.exists) {
      print("No dances found under admins/$_adminId/dances");
      return null;
    }

    for (final danceEntry in dancesSnap.children) {
      final danceId = danceEntry.key;
      if (danceId == null || danceId.isEmpty) continue;

      for (final genderEntry in ['Men', 'Women']) {
        final costumesRef = FirebaseDatabase.instance
            .ref('admins/$_adminId/dances/$danceId/costumes/$genderEntry/$costumeId');
        final costumeSnap = await costumesRef.get();

        if (costumeSnap.exists) {
          print("Found costume.");
          return {'danceId': danceId, 'gender': genderEntry};
        }
      }
    }
    print("Costume $costumeId not found in any dance/gender");
    return null;
  }

  Future<void> deleteCostume(String costumeId) async {
    if (_adminId == null || _danceId == null || _gender == null) return;

    final ref = FirebaseDatabase.instance
        .ref('admins/$_adminId/dances/$_danceId/costumes/$_gender/$costumeId');
    
    await ref.remove();
  
    _costumes.removeWhere((c) => c.id == costumeId);
    notifyListeners();
  }

  @override
  void dispose() {
    _costumesSubscription?.cancel();
    super.dispose();
  }
}