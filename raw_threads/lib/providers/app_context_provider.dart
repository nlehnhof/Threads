import 'package:flutter/material.dart';
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
      // User not logged in, can't initialize adminId
      _initialized = true;
      notifyListeners();
      return;
    }

    try {
      // Step 1: Get the adminCode for the current user
      final userSnap = await FirebaseDatabase.instance
          .ref('users/${user.uid}/adminCode')
          .get();

      if (!userSnap.exists || userSnap.value == null) {
        _initialized = true;
        notifyListeners();
        return;
      }
      _adminCode = userSnap.value as String;

      // Step 2: Search /admins for a matching adminCode
      final adminsSnap = await FirebaseDatabase.instance.ref('admins').get();

      // Defensive check
      if (!adminsSnap.exists) {
        _initialized = true;
        notifyListeners();
        return;
      }

      for (final entry in adminsSnap.children) {
        final codeSnap = entry.child('admincode');
        if (codeSnap.exists && codeSnap.value == _adminCode) {
          _adminId = entry.key;
          break;
        }
      }
    } catch (e) {
      debugPrint('Error initializing AppContextProvider: $e');
    }

    _initialized = true;
    notifyListeners();
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
