import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CostumeInventoryService {
  CostumeInventoryService._privateConstructor();
  static final CostumeInventoryService instance = CostumeInventoryService._privateConstructor();

  List<CostumePiece> _cachedCostumes = [];

  List<CostumePiece> get costumes => List.unmodifiable(_cachedCostumes);

  /// Add a costume to Firebase only
  Future<void> add(String danceId, String gender, CostumePiece costume) async {
    final adminId = await authService.value.getEffectiveAdminId();
    print('Admin ID: $adminId');
    if (adminId == null) {
      print('Admin is null.');
      return;
    }

    print('Adding costume to admins/$adminId/dances/$danceId/costumes/$gender/${costume.id}');
    print('Costume JSON: ${costume.toJson()}');

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender/${costume.id}');

    await ref.set(costume.toJson());
    
    final snapshot = await ref.get();

    if (snapshot.exists) {
      print('Verified costume added: ${snapshot.value}');
    } else {
      print('Error: Costume was not found after adding!');
    }
    // Do NOT update _cachedCostumes here, the listener will handle it.
  }

  Future<void> load(String danceId, String gender) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_getCostumeKey(danceId, gender));
    if (data == null) {
      _cachedCostumes = [];
      return;
    }

    final decoded = json.decode(data);
    _cachedCostumes = (decoded as List).map((item) => CostumePiece.fromJson(item)).toList();
  }

  String _getCostumeKey(String danceId, String gender) {
    return 'costumes_${danceId}_$gender';
  }

  /// Update a costume on Firebase only
  Future<void> update(String danceId, String gender, CostumePiece updatedCostume) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return;

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender/${updatedCostume.id}');

    await ref.set(updatedCostume.toJson());
    // Do NOT update _cachedCostumes here.
  }

  /// Delete a costume on Firebase only
  Future<void> delete(String danceId, String gender, String costumeId) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return;

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender/$costumeId');

    await ref.remove();
    // Do NOT update _cachedCostumes here.
  }


  /// Finds the danceId and gender for a costumeId by searching all dances and genders
  Future<Map<String, String>?> findCostumePath(String targetCostumeId) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return null;

    final dancesSnap = await FirebaseDatabase.instance
        .ref('admins/$adminId/dances')
        .get();

    final dances = dancesSnap.value as Map?;

    if (dances == null) return null;

    for (final danceEntry in dances.entries) {
      final danceId = danceEntry.key;
      final dance = danceEntry.value;

      for (final gender in ['Men', 'Women']) {
        final genderCostumes = (dance['costumes']?[gender]) as Map?;

        if (genderCostumes != null && genderCostumes.containsKey(targetCostumeId)) {
          return {
            'danceId': danceId,
            'gender': gender,
          };
        }
      }
    }

    return null;
  }
  
  /// Listen to Firebase updates for costumes under a specific dance and gender
  Future<StreamSubscription?> listenToCostumes({
    required String danceId,
    required String gender,
    required void Function(List<CostumePiece>) onUpdate,
  }) async {
    final adminId = await authService.value.getEffectiveAdminId();
    if (adminId == null) return null;

    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/dances/$danceId/costumes/$gender');

    return ref.onValue.listen((event) {
      final data = event.snapshot.value;

      if (data is Map) {
        final costumes = data.entries.map((entry) {
          final json = Map<String, dynamic>.from(entry.value);
          return CostumePiece.fromJson(json);
        }).toList();

        _cachedCostumes = costumes;
        onUpdate(costumes);
      } else {
        _cachedCostumes = [];
        onUpdate([]);
      }
    });
  }
}
