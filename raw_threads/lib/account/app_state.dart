import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppState extends ChangeNotifier {
  String? _adminId;
  String? _role;       // 'admin' or 'user'
  String? _adminCode;
  bool _isInitialized = false;

  String? get adminId => _adminId;
  String? get role => _role;
  String? get adminCode => _adminCode;
  bool get isInitialized => _isInitialized;

  void setAdminId(String? id) {
    if (_adminId != id) {
      _adminId = id;
      notifyListeners();
    }
  }

  void setRole(String? newRole) {
    if (_role != newRole) {
      _role = newRole;
      notifyListeners();
    }
  }

  void setAdminCode(String? code) {
    if (_adminCode != code) {
      _adminCode = code;
      notifyListeners();
    }
  }

  void reset() {
    _adminId = null;
    _role = null;
    _adminCode = null;
    _isInitialized = false;
    notifyListeners();
  }

  Future<void> initialize({String? uid}) async {
    _isInitialized = false;
    notifyListeners();

    if (uid == null) {
      reset();
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      final userSnap = await FirebaseDatabase.instance.ref('users/$uid').get();
      final userData = userSnap.exists 
          ? Map<String, dynamic>.from(userSnap.value as Map) 
          : {};

      final String roleFromDb = userData['role'] as String? ?? 'user';
      _role = roleFromDb;

      if (roleFromDb == 'admin') {
        _adminId = uid;
      } else {
        _adminId = userData['linkedAdminId'] as String?;
      }
    } catch (e) {
      debugPrint('Error initializing AppState: $e');
      reset();
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> logout() async {
  try {
    // Sign out from Firebase Auth
    await FirebaseAuth.instance.signOut();

    // Clear all state
    reset();
  } catch (e) {
    debugPrint('Logout failed: $e');
  }
}
}