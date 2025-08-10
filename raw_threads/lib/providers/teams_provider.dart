import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../classes/main_classes/teams.dart';

const uuid = Uuid();

class TeamProvider with ChangeNotifier {
  final _dbRef = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  String? role;
  String? adminCode;
  String? assignedTeamId; // For regular users
  String? assignedTeamName; // For showing team name to regular users

  List<Map<String, dynamic>> members = []; // All linked users
  List<Map<String, dynamic>> unassignedUsers = [];
  List<Teams> teams = [];
  bool isLoading = true;

  StreamSubscription<DatabaseEvent>? _membersSub;
  StreamSubscription<DatabaseEvent>? _teamsSub;

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

    if (role == 'admin') {
      await _loadOrGenerateAdminCode(currentUser.uid);
      _listenToTeams(adminCode!);
      _listenToMembers(currentUser.uid);
    } else {
      await _loadAssignedTeam(currentUser.uid);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAssignedTeam(String uid) async {
    final adminIdSnap = await _dbRef.child('users/$uid/adminId').get();
    if (!adminIdSnap.exists) return;
    final adminId = adminIdSnap.value as String;

    final teamsSnap = await _dbRef.child('teams/$adminId').get();
    if (!teamsSnap.exists) return;

    final allTeams = Map<String, dynamic>.from(teamsSnap.value as Map);
    for (var entry in allTeams.entries) {
      final teamData = Map<String, dynamic>.from(entry.value);
      final membersMap = Map<String, dynamic>.from(teamData['members'] ?? {});
      if (membersMap.containsKey(uid)) {
        assignedTeamId = entry.key;
        assignedTeamName = teamData['title'] ?? 'Unnamed Team';
        break;
      }
    }
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

  void _listenToTeams(String adminCode) {
    _teamsSub?.cancel();
    _teamsSub = _dbRef.child('teams/$adminCode').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      teams = data.entries.map((e) {
        final val = Map<String, dynamic>.from(e.value);
        return Teams(
          id: e.key,
          title: val['title'] ?? '',
          members: List<String>.from((val['members'] ?? {}).keys),
          assigned: List<String>.from((val['assigned'] ?? {}).keys),
        );
      }).toList();
      _updateUnassignedUsers();
      notifyListeners();
    });
  }

  void _listenToMembers(String adminUid) {
    _membersSub?.cancel();
    _membersSub = _dbRef
        .child('users')
        .orderByChild('adminId')
        .equalTo(adminUid)
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      members = data.entries.map((e) {
        final val = Map<String, dynamic>.from(e.value);
        return {
          'uid': e.key,
          'username': val['username'] ?? 'Unknown',
        };
      }).toList();
      _updateUnassignedUsers();
      notifyListeners();
    });
  }

  void _updateUnassignedUsers() {
    final assignedUids = teams.expand((t) => t.members).toSet();
    unassignedUsers = members.where((m) => !assignedUids.contains(m['uid'])).toList();
  }

  Future<void> addTeam(String title) async {
    if (adminCode == null) return;
    final newId = uuid.v4();
    final newTeam = {
      'title': title,
      'members': {},
      'assigned': {},
    };
    await _dbRef.child('teams/$adminCode/$newId').set(newTeam);
  }

  Future<void> assignUserToTeam(String userId, String teamId) async {
    if (adminCode == null) return;

    // Remove from all other teams first
    for (var t in teams) {
      await _dbRef.child('teams/$adminCode/${t.id}/members/$userId').remove();
    }
    // Add to selected team
    await _dbRef.child('teams/$adminCode/$teamId/members/$userId').set(true);
  }

  Future<void> assignDanceToTeam(String danceId, String teamId) async {
    if (adminCode == null) return;
    await _dbRef.child('teams/$adminCode/$teamId/assigned/$danceId').set(true);
  }

  String usernameFor(String uid) {
    return members.firstWhere((m) => m['uid'] == uid, orElse: () => {'username': 'Unknown'})['username']!;
  }

  @override
  void dispose() {
    _membersSub?.cancel();
    _teamsSub?.cancel();
    super.dispose();
  }
}
