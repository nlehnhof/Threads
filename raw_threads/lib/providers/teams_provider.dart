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
  Query? _usersRef;
  StreamSubscription<DatabaseEvent>? _teamsSub;
  StreamSubscription<DatabaseEvent>? _usersSub;

  TeamProvider({required this.adminId});

  /// Initialize provider
  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Load admin code and user role
    await _loadAdminCode();
    await _loadCurrentUserRole(currentUser.uid);

    // Listen to teams and users in real-time
    _listenToTeams();
    _listenToUsernames();

    isLoading = false;
    notifyListeners();
  }

  /// Load admin code once
  Future<void> _loadAdminCode() async {
    final snap = await _db.child('admins/$adminId/admincode').get();
    if (snap.exists && snap.value != null) {
      adminCode = snap.value as String;
    }
  }

  /// Load current user's role
  Future<void> _loadCurrentUserRole(String userId) async {
    final snap = await _db.child('users/$userId').get();
    if (snap.exists && snap.value != null) {
      role = (snap.value as Map)['role'] ?? 'user';
    }
  }

  /// Listen to teams in real-time
  void _listenToTeams() {
    _teamsRef = _db.child('admins/$adminId/teams');
    _teamsSub?.cancel();

    _teamsSub = _teamsRef!.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
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

  /// Listen to usernames of linked users in real-time
  void _listenToUsernames() {
    _usersRef = _db.child('users').orderByChild('linkedAdminId').equalTo(adminId);
    _usersSub?.cancel();

    _usersSub = _usersRef!.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        usernames.clear();
      } else {
        final Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
        usernames = data.map((uid, value) {
          final user = Map<String, dynamic>.from(value);
          return MapEntry(uid, user['username'] ?? 'Unknown');
        });
      }
      _assignUsers(FirebaseAuth.instance.currentUser!.uid);
      notifyListeners();
    });
  }

  /// Assign unassigned users and set current user's team
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

  // --- Team CRUD ---
  Future<void> addTeam(String title) async {
    final teamId = _db.child('admins/$adminId/teams').push().key!;
    final newTeam = Teams(id: teamId, title: title, members: [], assigned: []);
    await _db.child('admins/$adminId/teams/$teamId').set(newTeam.toJson());

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
    _usersSub?.cancel();
    super.dispose();
  }
}
