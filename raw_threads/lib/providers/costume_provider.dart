import 'dart:async';

import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/services/costume_inventory_service.dart';

class CostumesProvider extends ChangeNotifier {
  final String danceId;
  final String gender;

  List<CostumePiece> _costumes = [];
  List<CostumePiece> get costumes => List.unmodifiable(_costumes);
  StreamSubscription<dynamic>? _subscription;

  CostumesProvider({
    // super.key,
    required this.danceId,
    required this.gender,
  }) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Start listening to Firebase changes
    _subscription = await CostumeInventoryService.instance.listenToCostumes(
      danceId: danceId,
      gender: gender,
      onUpdate: (updatedList) {
        _costumes = updatedList;
        notifyListeners();
      },
    );
  }

  Future<void> addCostume(CostumePiece costume) async {
    await CostumeInventoryService.instance.add(danceId, gender, costume);
    // The listener will automatically update the local list.
  }

  Future<void> updateCostume(CostumePiece costume) async {
    await CostumeInventoryService.instance.update(danceId, gender, costume);
  }

  Future<void> deleteCostume(String costumeId) async {
    await CostumeInventoryService.instance.delete(danceId, gender, costumeId);
  }

  Future<void> loadCostume(CostumePiece costume) async {
    await CostumeInventoryService.instance.load(danceId, gender);
  }

  @override
  void dispose() {
    _subscription?.cancel(); // Clean up listener
    super.dispose();
  }
}
