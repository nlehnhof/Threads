import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../classes/main_classes/costume_piece.dart';

class CostumeInventoryService {
  static final CostumeInventoryService instance = CostumeInventoryService._privateConstructor();

  CostumeInventoryService._privateConstructor();

  static const String _prefsKeyPrefix = 'costumes_for_dance_';

  final Map<String, List<CostumePiece>> _costumesByDance = {};

  Future<void> loadForDance(String danceId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_prefsKeyPrefix$danceId');
    if (jsonString == null) {
      _costumesByDance[danceId] = [];
      return;
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    _costumesByDance[danceId] = jsonList.map((item) => CostumePiece.fromMap(item)).toList();
  }

  List<CostumePiece> getCostumes(String danceId) {
    return _costumesByDance[danceId] ?? [];
  }

  Future<void> addCostume(String danceId, CostumePiece piece) async {
    final list = _costumesByDance[danceId] ?? [];
    list.add(piece);
    _costumesByDance[danceId] = list;
    await saveForDance(danceId);
  }

  Future<void> saveForDance(String danceId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _costumesByDance[danceId] ?? [];
    final jsonString = json.encode(list.map((c) => c.toMap()).toList());
    await prefs.setString('$_prefsKeyPrefix$danceId', jsonString);
  }
}
