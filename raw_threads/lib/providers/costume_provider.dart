import 'dart:async';
import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/services/costume_inventory_service.dart';

class CostumesProvider extends ChangeNotifier {
  String? _danceId;
  String? _gender;

  List<CostumePiece> _costumes = [];
  List<CostumePiece> get costumes => List.unmodifiable(_costumes);

  StreamSubscription<dynamic>? _subscription;
  CostumesProvider();

  final Map<String, Map<String, List<CostumePiece>>> _costumesByDance = {};

    /// Find the danceId and gender for a costume by its ID.
  Future<Map<String, String>?> findPath(String costumeId) async {
    for (var danceEntry in _costumesByDance.entries) {
      final danceId = danceEntry.key;
      final genderMap = danceEntry.value;

      for (var genderEntry in genderMap.entries) {
        final gender = genderEntry.key;
        final costumes = genderEntry.value;
        
        if (costumes.any((c) => c.id == costumeId)) {
          return {
            'danceId': danceId,
            'gender': gender,
          };
        }
      }
    }
    return null; // Not found
  }

  void updateContext(String? danceId, String? gender) {
    if (_danceId == danceId && _gender == gender) return; // no change
    _danceId = danceId;
    _gender = gender;

    _subscription?.cancel();
    _costumes = [];

    if (_danceId != null && _gender != null) {
      initialize();
    } else {
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (_danceId == null || _gender == null) return;

    _subscription = await CostumeInventoryService.instance.listenToCostumes(
      danceId: _danceId!,
      gender: _gender!,
      onUpdate: (updatedList) {
        _costumes = updatedList;
        notifyListeners();
      },
    );
  }

  Future<void> addCostume(CostumePiece costume) async {
    print('Adding costume to dance $_danceId gender $_gender');
    if (_danceId == null || _gender == null) return;
    await CostumeInventoryService.instance.add(_danceId!, _gender!, costume);
  }

  Future<void> updateCostume(CostumePiece costume) async {
    if (_danceId == null || _gender == null) return;
    await CostumeInventoryService.instance.update(_danceId!, _gender!, costume);
  }

  Future<void> deleteCostume(String costumeId) async {
    if (_danceId == null || _gender == null) return;
    await CostumeInventoryService.instance.delete(_danceId!, _gender!, costumeId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
