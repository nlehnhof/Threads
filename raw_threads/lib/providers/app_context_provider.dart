import 'package:flutter/material.dart';
import 'package:raw_threads/providers/costume_provider.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';

class AppContextProvider extends ChangeNotifier {
  String? _adminId;
  String? _danceId;
  String? _gender;
  String? _costumeId;

  String? get adminId => _adminId;
  String? get danceId => _danceId;
  String? get gender => _gender;
  String? get costumeId => _costumeId;

  void clearContext() {
    _danceId = null;
    _gender = null;
    _costumeId = null;
    notifyListeners();
  }

  /// Sets context by looking up danceId & gender dynamically
  Future<void> setCostumeContextById(CostumePiece costume, CostumesProvider costumesProvider) async {
    final result = await costumesProvider.findPath(costume.id);
    if (result != null) {
      _danceId = result['danceId'];
      _gender = result['gender'];
      _costumeId = costume.id;
      notifyListeners();
    }
  }

  void setCostumeContext({required String danceId, required String gender, required String costumeId}) {
    _danceId = danceId;
    _gender = gender;
    _costumeId = costumeId;
    notifyListeners();
  }

  void setAdminId(String id) {
    _adminId = id;
    notifyListeners();
  }

  void setDanceId(String id) {
    _danceId = id;
    notifyListeners();
  }

  void setGender(String gender) {
    _gender = gender;
    notifyListeners();
  }

  void setCostumeId(String id) {
    _costumeId = id;
    notifyListeners();
  }
}
