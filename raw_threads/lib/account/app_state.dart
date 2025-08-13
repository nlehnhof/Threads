import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AppState extends ChangeNotifier {
  String? _adminId;
  String? _role;       // e.g., 'admin' or 'user'
  String? _adminCode;
  bool _isInitialized = false;

  String? get adminId => _adminId;
  String? get role => _role;
  String? get adminCode => _adminCode;
  bool get isInitialized => _isInitialized;

  // Setter for adminId with notification
  void setAdminId(String? id) {
    if (_adminId != id) {
      _adminId = id;
      notifyListeners();
    }
  }

  // Setter for role with notification
  void setRole(String? newRole) {
    if (_role != newRole) {
      _role = newRole;
      notifyListeners();
    }
  }

  // Setter for adminCode with notification
  void setAdminCode(String? code) {
    if (_adminCode != code) {
      _adminCode = code;
      notifyListeners();
    }
  }

  void clearAdmin() {
    _adminId = null;
    _role = null;
    _adminCode = null;
    notifyListeners();
  }

  /// Initializes AppState by checking current user info and linked admin
  Future<void> initialize() async {
    _isInitialized = false;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // No logged-in user
        _adminId = null;
        _role = null;
        _adminCode = null;
        _isInitialized = true;
        notifyListeners();
        return;
      }

      // Fetch user role from database or infer from Auth or custom claims
      // Example: check 'users/{uid}/role' in Firebase DB
      final userRoleSnap = await FirebaseDatabase.instance
          .ref('users/${user.uid}/role')
          .get();

      if (userRoleSnap.exists && userRoleSnap.value != null) {
        _role = userRoleSnap.value as String;
      } else {
        // Default or fallback role, e.g., 'user'
        _role = 'user';
      }

      // If user is admin, adminId is own uid
      if (_role == 'admin') {
        _adminId = user.uid;
        _adminCode = null; // Admin code not needed for admin themselves
      } else {
        // For regular user, fetch linked adminCode and find matching adminId
        final adminCodeSnap = await FirebaseDatabase.instance
            .ref('users/${user.uid}/linkedAdminCode')
            .get();

        if (adminCodeSnap.exists && adminCodeSnap.value != null) {
          _adminCode = adminCodeSnap.value as String;

          // Find adminId by adminCode
          final adminsSnap = await FirebaseDatabase.instance.ref('admins').get();

          if (adminsSnap.exists) {
            String? foundAdminId;
            for (final adminEntry in adminsSnap.children) {
              final codeSnap = adminEntry.child('admincode');
              if (codeSnap.exists && codeSnap.value == _adminCode) {
                foundAdminId = adminEntry.key;
                break;
              }
            }
            _adminId = foundAdminId;
          } else {
            _adminId = null;
          }
        } else {
          _adminId = null;
          _adminCode = null;
        }
      }
    } catch (e) {
      debugPrint('Error initializing AppState: $e');
      _adminId = null;
      _adminCode = null;
      _role = null;
    }

    _isInitialized = true;
    notifyListeners();
  }
}
