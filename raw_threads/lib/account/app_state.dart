import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

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
}


// {
//   "rules": {
//     "admins": {
//       "$adminId": {
//         ".read": "auth != null && (auth.uid === $adminId || root.child('users').child(auth.uid).child('linkedAdminId').val() === $adminId)",
//         ".write": "auth != null && auth.uid === $adminId",

//         "teams": {
//           "$teamId": {
//             ".read": "auth != null && (auth.uid === $adminId || root.child('users').child(auth.uid).child('linkedAdminId').val() === $adminId)",
//             ".write": "auth != null && auth.uid === $adminId"
//           }
//         },

//         "repairs": {
//           "$repairId": {
//             ".read": "auth != null && (auth.uid === $adminId || root.child('users').child(auth.uid).child('linkedAdminId').val() === $adminId)",
//             ".write": "auth != null && (auth.uid === $adminId || root.child('users').child(auth.uid).child('linkedAdminId').val() === $adminId)"
//           }
//         }
//       }
//     },

//     "users": {
//       "$userId": {
//         ".read": "auth != null && (auth.uid === $userId || root.child('users').child($userId).child('linkedAdminId').val() === auth.uid)",
//         ".write": "auth != null && auth.uid === $userId"
//       },
//       ".indexOn": ["linkedAdminId"]
//     },

//     "adminCodes": {
//       "$code": {
//         ".read": "auth != null",
//         ".write": "auth != null && root.child('admins').child(auth.uid).exists()"
//       }
//     }
//   }
// }
