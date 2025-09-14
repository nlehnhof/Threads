import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:raw_threads/classes/main_classes/teams.dart';
import 'package:raw_threads/classes/main_classes/app_user.dart';
import 'package:raw_threads/classes/main_classes/shows.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'dart:async';

class TeamProvider extends ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;

  List<Teams> teams = [];
  List<AppUser> linkedUsers = [];
  String adminCode = '';
  String? assignedTeamId;

  TeamProvider();

StreamSubscription<DatabaseEvent>? _teamsSub;
StreamSubscription<DatabaseEvent>? _usersSub;

Future<void> init() async {
  isLoading = true;
  notifyListeners();

  try {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Step 1: Get user role
    final roleSnap = await _dbRef.child('users/${currentUser.uid}/role').get();
    final role = roleSnap.exists ? roleSnap.value as String : 'user';

    String? adminId;
    if (role == 'admin') {
      adminId = currentUser.uid;
    } else {
      // Regular user linked to admin
      final linkSnap =
          await _dbRef.child('users/${currentUser.uid}/linkedAdminId').get();
      adminId = linkSnap.exists ? linkSnap.value as String : null;

      // Store assigned team for user
      final teamSnap =
          await _dbRef.child('users/${currentUser.uid}/assignedTeamId').get();
      assignedTeamId =
          teamSnap.exists ? teamSnap.value as String : null;
    }

    if (adminId != null) {
      // Admin code
      final codeSnap =
          await _dbRef.child('admins/$adminId/admincode').get();
      adminCode = codeSnap.exists
          ? codeSnap.value as String
          : adminId.substring(0, 6);

      // --- LISTEN TO TEAMS ---
      _teamsSub?.cancel();
      _teamsSub =
          _dbRef.child('admins/$adminId/teams').onValue.listen((event) {
        teams = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          (event.snapshot.value as Map).forEach((key, value) {
            teams.add(Teams.fromJson({
              'id': key,
              ...Map<String, dynamic>.from(value)
            }));
          });
        }
        notifyListeners();
      });

      // --- LISTEN TO USERS ---
      _usersSub?.cancel();
      _usersSub = _dbRef.child('users').onValue.listen((event) {
        linkedUsers = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          for (final userSnap in event.snapshot.children) {
            final userMap = userSnap.value as Map<dynamic, dynamic>;
            if (userMap['linkedAdminId'] == adminId) {
              linkedUsers.add(AppUser.fromJson({
                'id': userSnap.key,
                ...Map<String, dynamic>.from(userMap)
              }));
            }
          }
        }
        notifyListeners();
      });
    }
  } catch (e) {
    debugPrint('TeamProvider init error: $e');
  } finally {
    isLoading = false;
    notifyListeners();
  }
}

@override
void dispose() {
  _teamsSub?.cancel();
  _usersSub?.cancel();
  super.dispose();
}

  /// Get username for user ID
  String usernameFor(String uid) {
    final user = linkedUsers.firstWhere(
      (u) => u.id == uid,
      orElse: () => AppUser(id: uid, email: '', username: 'Unknown', role: 'user'),
    );
    return user.username;
  }

  // --- Team Management ---
  Future<void> addTeam(String title) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final teamRef = _dbRef.child('admins/${currentUser.uid}/teams').push();
    final newTeam = Teams(id: teamRef.key!, title: title, members: [], assigned: []);
    await teamRef.set(newTeam.toJson());
    teams.add(newTeam);
    notifyListeners();
  }

  Future<void> renameTeam(String teamId, String newTitle) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _dbRef.child('admins/${currentUser.uid}/teams/$teamId/title').set(newTitle);
    final team = teams.firstWhere((t) => t.id == teamId);
    team.title = newTitle;
    notifyListeners();
  }

  Future<void> deleteTeam(String teamId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _dbRef.child('admins/${currentUser.uid}/teams/$teamId').remove();
    teams.removeWhere((t) => t.id == teamId);
    notifyListeners();
  }

  // --- User Assignment ---
  Future<void> assignUserToTeam(String uid, String teamId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final team = teams.firstWhere((t) => t.id == teamId);
    if (!team.members.contains(uid)) team.members.add(uid);

    await _dbRef.child('admins/${currentUser.uid}/teams/$teamId/members').set(team.members);
    await _dbRef.child('users/$uid/assignedTeamId').set(teamId);

    notifyListeners();
  }

Future<void> removeUserFromTeam(String uid, String teamId) async {
  final currentUser = _auth.currentUser;
  if (currentUser == null) return;

  final team = teams.firstWhere((t) => t.id == teamId);
  team.members.remove(uid);

  await _dbRef.child('admins/${currentUser.uid}/teams/$teamId/members').set(team.members);

  // Explicitly set assignedTeamId to null in Firebase
  await _dbRef.child('users/$uid/assignedTeamId').set(null);

  // Update locally with copyWith
  final userIndex = linkedUsers.indexWhere((u) => u.id == uid);
  if (userIndex != -1) {
    linkedUsers[userIndex] = linkedUsers[userIndex].copyWith(assignedTeamId: null);
  }

  notifyListeners();
}

  // --- Dance Assignment ---
  Future<void> assignDanceToTeam(String teamId, String danceId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final team = teams.firstWhere((t) => t.id == teamId);
    if (!team.assigned.contains(danceId)) team.assigned.add(danceId);

    await _dbRef.child('admins/${currentUser.uid}/teams/$teamId/assigned').set(team.assigned);
    notifyListeners();
  }

  Future<void> unassignDanceFromTeam(String teamId, String danceId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final team = teams.firstWhere((t) => t.id == teamId);
    team.assigned.remove(danceId);

    await _dbRef.child('admins/${currentUser.uid}/teams/$teamId/assigned').set(team.assigned);
    notifyListeners();
  }

  // --- Helper Getters ---
  List<String> getDanceIdsForTeam(String teamId) {
    final team = teams.firstWhere(
      (t) => t.id == teamId,
      orElse: () => Teams(id: '', title: '', members: [], assigned: []),
    );
    return team.assigned;
  }

  /// Completely unlink a user from this admin (linkedAdminId -> null)
  Future<void> unlinkUserFromAdmin(String uid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Clear user's admin link and team assignment
    await _dbRef.child('users/$uid/linkedAdminId').remove();
    await _dbRef.child('users/$uid/assignedTeamId').remove();

    // Remove from local linkedUsers list
    linkedUsers.removeWhere((u) => u.id == uid);

    // Also clean up team memberships
    for (final team in teams) {
      if (team.members.contains(uid)) {
        team.members.remove(uid);
        await _dbRef.child('admins/${currentUser.uid}/teams/${team.id}/members').set(team.members);
      }
    }

    notifyListeners();
  }

  List<Dances> getDancesForTeam(String teamId, List<Dances> allDances) {
    final danceIds = getDanceIdsForTeam(teamId);
    return allDances.where((d) => danceIds.contains(d.id)).toList();
  }

  List<Shows> getShowsForTeam(String teamId, List<Shows> allShows) {
    final danceIds = getDanceIdsForTeam(teamId);
    return allShows.where((s) => s.danceIds.any((id) => danceIds.contains(id))).toList();
  }

  List<String> getTeamNamesForDance(String danceId) {
    return teams.where((t) => t.assigned.contains(danceId)).map((t) => t.title).toList();
  }
}
