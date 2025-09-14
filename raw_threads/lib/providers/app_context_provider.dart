import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AppContextProvider extends ChangeNotifier {
  String? _adminId;
  String? _adminCode;

  String? get adminId => _adminId;
  String? get adminCode => _adminCode;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  AppContextProvider() {
    _initialize();
  }

Future<void> _initialize() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    _initialized = true;
    notifyListeners();
    return;
  }

  try {
    // Step 1: Check if user is already linked to an admin
    final linkSnap = await FirebaseDatabase.instance.ref('users/${user.uid}/linkedAdminId').get();
    if (linkSnap.exists && linkSnap.value != null) {
      _adminId = linkSnap.value as String;

      // Load adminCode
      final codeSnap = await FirebaseDatabase.instance.ref('admins/$_adminId/admincode').get();
      _adminCode = codeSnap.exists ? codeSnap.value as String : _adminId!.substring(0, 6);

      _initialized = true;
      notifyListeners();
      return;
    }

    // --- New user: not linked yet ---
    // Just mark initialized and let UI show admin code input box
    _initialized = true;
    notifyListeners();
  } catch (e) {
    debugPrint('Error initializing AppContextProvider: $e');
    _initialized = true;
    notifyListeners();
  }
}

Future<bool> linkAdmin(String code) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  try {
    final adminsSnap = await FirebaseDatabase.instance.ref('admins').get();
    if (!adminsSnap.exists) return false;

    for (final entry in adminsSnap.children) {
      final codeSnap = entry.child('admincode');
      if (codeSnap.exists && codeSnap.value == code) {
        _adminId = entry.key;
        _adminCode = code;

        // Option B linking
        await FirebaseDatabase.instance.ref('users/${user.uid}/linkedAdminId').set(_adminId);
        await FirebaseDatabase.instance.ref('admins/$_adminId/linkedUsers/${user.uid}').set(true);

        notifyListeners();
        return true;
      }
    }
  } catch (e) {
    debugPrint('Error linking admin: $e');
  }

  return false;
}


  void setAdminId(String id) {
    _adminId = id;
    debugPrint('AppContextProvider.adminId set to $_adminId');
    notifyListeners();
  }

  Future<void> refresh() async {
    _initialized = false;
    _adminId = null;
    _adminCode = null;
    notifyListeners();
    await _initialize();
  }
}
