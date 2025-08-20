import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:raw_threads/classes/main_classes/teams.dart';

class TeamProvider extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final String adminId;

  String adminCode = '';
  List<Teams> teams = [];
  List<Map<String, dynamic>> unassignedUsers = [];
  String role = 'user';
  bool isLoading = true;
  String? assignedTeamId;

  Map<String, String> usernames = {};
  DatabaseReference? _teamsRef;
  StreamSubscription<DatabaseEvent>? _teamsSub;

  TeamProvider({required this.adminId});

  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await Future.wait([
      _loadAdminCode(),
      _loadAllUsernames(),
    ]);

    _listenToTeams();

    _assignUsers(currentUser.uid);
    await _loadCurrentUserRole(currentUser.uid);

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAdminCode() async {
    final snap = await _db.child('admins/$adminId/admincode').get();
    if (snap.exists) adminCode = snap.value as String;
  }

  Future<void> _loadAllUsernames() async {
    final snap = await _db.child('users').orderByChild('linkedAdminId').equalTo(adminId).get();
    if (!snap.exists) return;
    final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
    usernames.clear();
    data.forEach((uid, value) {
      final user = Map<String, dynamic>.from(value);
      usernames[uid] = user['username'] ?? 'Unknown';
    });
  }

  void _listenToTeams() {
    _teamsRef = _db.child('admins/$adminId/teams');
    _teamsSub = _teamsRef!.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        teams = data.entries
            .map((e) => Teams.fromJson(Map<String, dynamic>.from(e.value)))
            .toList();
      } else {
        teams = [];
      }
      _assignUsers(FirebaseAuth.instance.currentUser!.uid);
      notifyListeners();
    });
  }

  void _assignUsers(String currentUserId) {
    unassignedUsers.clear();
    assignedTeamId = null;
    for (var entry in usernames.entries) {
      final uid = entry.key;
      final team = teams.firstWhere(
        (t) => t.members.contains(uid),
        orElse: () => Teams(id: '', title: '', members: [], assigned: []),
      );
      if (team.id.isEmpty) {
        unassignedUsers.add({'uid': uid, 'username': entry.value});
      } else if (uid == currentUserId) {
        assignedTeamId = team.id;
      }
    }
  }

  Future<void> _loadCurrentUserRole(String userId) async {
    final snap = await _db.child('users/$userId').get();
    if (snap.exists) role = (snap.value as Map)['role'] ?? 'user';
  }

  // --- Team CRUD ---
  Future<void> addTeam(String title) async {
    final teamId = _db.child('admins/$adminId/teams').push().key!;
    final newTeam = Teams(id: teamId, title: title, members: [], assigned: []);
    await _db.child('admins/$adminId/teams/$teamId').set(newTeam.toJson());

    // Update locally for instant UI feedback
    teams.add(newTeam);
    notifyListeners();
  }

  Future<void> renameTeam(String teamId, String newTitle) async {
    await _db.child('admins/$adminId/teams/$teamId/title').set(newTitle);
  }

  Future<void> deleteTeam(String teamId) async {
    await _db.child('admins/$adminId/teams/$teamId').remove();
  }

  // --- User management ---
  Future<void> assignUserToTeam(String userId, String teamId) async {
    for (var t in teams) {
      if (t.members.contains(userId)) {
        t.members.remove(userId);
        await _db.child('admins/$adminId/teams/${t.id}/members').set(t.members);
      }
    }

    final team = teams.firstWhere((t) => t.id == teamId);
    team.members.add(userId);
    await _db.child('admins/$adminId/teams/$teamId/members').set(team.members);
  }

  Future<void> removeUserFromTeam(String userId, String teamId) async {
    final team = teams.firstWhere((t) => t.id == teamId);
    team.members.remove(userId);
    await _db.child('admins/$adminId/teams/$teamId/members').set(team.members);
  }

  // --- Dance assignment ---
  Future<void> assignDanceToTeam(String teamId, String danceId) async {
    final team = teams.firstWhere((t) => t.id == teamId);
    if (!team.assigned.contains(danceId)) {
      team.assigned.add(danceId);
      await _db.child('admins/$adminId/teams/$teamId/assigned').set(team.assigned);
      notifyListeners();
    }
  }

  Future<void> unassignDanceFromTeam(String teamId, String danceId) async {
    final team = teams.firstWhere((t) => t.id == teamId);
    if (team.assigned.contains(danceId)) {
      team.assigned.remove(danceId);
      await _db.child('admins/$adminId/teams/$teamId/assigned').set(team.assigned);
      notifyListeners();
    }
  }

  List<String> getTeamNamesForDance(String danceId) {
    final teamsWithDance = teams.where((t) => t.assigned.contains(danceId));
    return teamsWithDance.map((t) => t.title).toList();
  }

  String usernameFor(String uid) => usernames[uid] ?? 'Unknown';

  @override
  void dispose() {
    _teamsSub?.cancel();
    super.dispose();
  }
}
