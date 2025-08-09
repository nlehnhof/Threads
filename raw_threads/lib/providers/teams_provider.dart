import 'dart:async';

import 'package:firebase_database/ui/utils/stream_subscriber_mixin.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeamProvider with ChangeNotifier {
  final _dbRef = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  String? role;
  String? adminCode;
  List<Map<String, String>> members = [];
  bool isLoading = true;

  StreamSubscription<DatabaseEvent>? _teamSubscription;

  Future<void> loadTeamData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    // Load role
    final roleSnap = await _dbRef.child('users/${currentUser.uid}/role').get();
    role = roleSnap.value as String?;

    // Admin-specific data
    if (role == 'admin') {
      await _loadOrGenerateAdminCode(currentUser.uid);
      _listenToTeamMembers(adminCode!);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadOrGenerateAdminCode(String uid) async {
    final codeSnap = await _dbRef.child('users/$uid/adminCode').get();
    if (codeSnap.exists) {
      adminCode = codeSnap.value as String;
    } else {
      adminCode = uid.substring(0, 6);
      await _dbRef.child('users/$uid').update({'adminCode': adminCode});
    }
  }

  void _listenToTeamMembers(String adminCode) {
    _teamSubscription?.cancel();
    _teamSubscription = _dbRef.child('teams/$adminCode/members').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      members = data.entries.map((e) {
        return {
          'uid': e.key.toString(),
          'username': (e.value['username'] ?? 'Unknown').toString(),
        };
      }).toList();
      notifyListeners();
    });
  }

  Future<void> removeMember(String uid) async {
    if (adminCode != null) {
      await _dbRef.child('teams/$adminCode/members/$uid').remove();
    }
  }

  @override
  void dispose() {
    _teamSubscription?.cancel();
    super.dispose();
  }
}
