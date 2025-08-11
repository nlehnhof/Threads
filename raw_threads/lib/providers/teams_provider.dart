import 'package:flutter/foundation.dart';
import 'package:raw_threads/classes/main_classes/teams.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class TeamProvider with ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  List<Teams> teams = [];
  String? role;
  String? adminCode;
  String? assignedTeamId; // for regular users
  String? assignedTeamName;

  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> unassignedUsers = [];
  bool isLoading = true;

  StreamSubscription<DatabaseEvent>? _membersSub;
  StreamSubscription<DatabaseEvent>? _teamsSub;

  Future<void> loadTeams() async {
    if (adminCode == null) return;

    _dbRef.child('teams').child(adminCode!).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      teams = data.entries.map((entry) {
        final value = entry.value as Map<dynamic, dynamic>;
        return Teams(
          id: entry.key,
          title: value['name'] ?? '',
          members: List<String>.from(value['members']?.keys ?? []),
          assigned: List<String>.from(value['assigned']?.keys ?? []),
        );
      }).toList();
      notifyListeners();
    });
  }

  Future<void> addDanceToTeam(String teamId, String danceId) async {
    if (adminCode == null) return;

    await _dbRef
        .child('teams')
        .child(adminCode!)
        .child(teamId)
        .child('assigned')
        .child(danceId)
        .set(true);

    final teamIndex = teams.indexWhere((t) => t.id == teamId);
    if (teamIndex != -1 && !teams[teamIndex].assigned.contains(danceId)) {
      teams[teamIndex].assigned.add(danceId);
      notifyListeners();
    }
  }

  Future<void> removeDanceFromTeam(String teamId, String danceId) async {
    if (adminCode == null) return;

    await _dbRef
        .child('teams')
        .child(adminCode!)
        .child(teamId)
        .child('assigned')
        .child(danceId)
        .remove();

    final teamIndex = teams.indexWhere((t) => t.id == teamId);
    if (teamIndex != -1) {
      teams[teamIndex].assigned.remove(danceId);
      notifyListeners();
    }
  }

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

  Future<void> assignDanceToTeamBidirectional(String danceId, String teamId) async {
    if (adminCode == null) return;

    final teamAssignedRef = _dbRef.child('teams/$adminCode/$teamId/assigned/$danceId');
    final danceAssignedTeamsRef = _dbRef.child('admins/$adminCode/dances/$danceId/assignedTeams/$teamId');

    // Set both assignments simultaneously
    await Future.wait([
      teamAssignedRef.set(true),
      danceAssignedTeamsRef.set(true),
    ]);

    // Update local state for teams list
    final teamIndex = teams.indexWhere((t) => t.id == teamId);
    if (teamIndex != -1 && !teams[teamIndex].assigned.contains(danceId)) {
      teams[teamIndex].assigned.add(danceId);
      notifyListeners();
    }
  }

  Future<void> unassignDanceFromTeamBidirectional(String danceId, String teamId) async {
    if (adminCode == null) return;

    final teamAssignedRef = _dbRef.child('teams/$adminCode/$teamId/assigned/$danceId');
    final danceAssignedTeamsRef = _dbRef.child('admins/$adminCode/dances/$danceId/assignedTeams/$teamId');

    // Remove both assignments simultaneously
    await Future.wait([
      teamAssignedRef.remove(),
      danceAssignedTeamsRef.remove(),
    ]);

    // Update local state for teams list
    final teamIndex = teams.indexWhere((t) => t.id == teamId);
    if (teamIndex != -1 && teams[teamIndex].assigned.contains(danceId)) {
      teams[teamIndex].assigned.remove(danceId);
      notifyListeners();
    }
  }


  List<String> getTeamNamesForDance(String danceId) {
    return teams
        .where((t) => t.assigned.contains(danceId))
        .map((t) => t.title)
        .toList();
  }

  Future<void> deleteTeam(String teamId) async {
    if (adminCode == null) return;
    await _dbRef.child('teams/$adminCode/$teamId').remove();
  }

  Future<void> renameTeam(String teamId, String newTitle) async {
    if (adminCode == null) return;
    await _dbRef.child('teams/$adminCode/$teamId').update({'title': newTitle});
  }

  Future<void> removeUserFromTeam(String userId, String teamId) async {
    if (adminCode == null) return;
    await _dbRef.child('teams/$adminCode/$teamId/members/$userId').remove();
  }

  Future<void> removeDanceFromTeam2(String teamId, String danceId) async {
    if (adminCode == null) return;

    final teamRef = _dbRef
        .child('admins')
        .child(adminCode!)
        .child('teams')
        .child(teamId)
        .child('assignedDances')
        .child(danceId);

    await teamRef.remove();

    // Also update the local state
    final teamIndex = teams.indexWhere((t) => t.id == teamId);
    if (teamIndex != -1) {
      teams[teamIndex].assigned.remove(danceId);
      notifyListeners();
    }
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
    final codeSnap = await _dbRef.child('admins/$uid/admincode').get();
    if (codeSnap.exists && codeSnap.value != null) {
      adminCode = codeSnap.value as String;
    } else {
      adminCode = uid.substring(0, 6).toUpperCase();
      await _dbRef.child('admins/$uid/admincode').set(adminCode);
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

  Future<void> updateDanceAssignments(Map<String, Set<String>> danceAssignments) async {
    if (adminCode == null) return;

    // Clear previous dance assignments on all teams
    for (var team in teams) {
      await _dbRef.child('teams/$adminCode/${team.id}/assigned').remove();
    }

    // Assign dances to teams in Firebase
    for (var entry in danceAssignments.entries) {
      final teamId = entry.key;
      final assignedDanceIds = entry.value;
      for (var danceId in assignedDanceIds) {
        await _dbRef.child('teams/$adminCode/$teamId/assigned/$danceId').set(true);
      }
    }
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

  Future<void> unassignDanceFromTeam(String danceId, String teamId) async {
    if (adminCode == null) return;
    await _dbRef.child('teams/$adminCode/$teamId/assigned/$danceId').remove();
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
