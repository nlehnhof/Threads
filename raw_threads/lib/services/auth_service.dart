import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:raw_threads/classes/main_classes/app_user.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Create a new user and store their email and role
  Future<void> createAccount({
    required String email,
    required String password,
    required String role,
    String? adminId,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        final userData = {
          'id': user.uid,
          'email': email,
          'role': role,
          'username': '',
        };
        if (role == 'user' && adminId != null) {
          userData['adminId'] = adminId;
        }
        await _dbRef.child('users').child(user.uid).set(userData);

        if (role == 'admin') {
          await _dbRef.child('admins').child(user.uid).set({
            'dances': {},
            'shows': {},
            'costumes': {},
            'repairs': {},
            'costumeItems': {},
            'issueItems': {},
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> ensureAdminCodeExists() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final adminId = user.uid;
    final adminCodeRef = _dbRef.child('admins').child(adminId).child('admincode');

    final snapshot = await adminCodeRef.get();

    if (!snapshot.exists) {
      // Generate adminCode, e.g. first 6 chars of UID
      final adminCode = adminId.substring(0, 6);
      await adminCodeRef.set(adminCode);
    }
  }

  Future<String?> getRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _dbRef.child('users').child(user.uid).get();
      if (snapshot.exists && snapshot.child('role').value != null) {
        return snapshot.child('role').value as String;
      }
    }
    return null;
  }

  Future<String?> getLinkedAdminId() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snapshot = await _dbRef.child('users').child(user.uid).child('adminId').get();
    if (snapshot.exists) {
      return snapshot.value as String?;
    }
    return null;
  }

  Future<String?> getEffectiveAdminId() async {
    final role = await getRole();
    if (role == 'admin') {
      return _auth.currentUser?.uid;
    } else {
      return await getLinkedAdminId();
    }
  }

  Future<Map<String, dynamic>> getShowsForAdmin(String adminId) async {
    try {
      final snapshot = await _dbRef.child('admins').child(adminId).child('shows').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return {};
    } catch (e) {
      debugPrint("Error fetching shows: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> getDancesForAdmin(String adminId) async {
    try {
      final snapshot = await _dbRef.child('admins').child(adminId).child('dances').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return {};
    } catch (e) {
      debugPrint("Error fetching dances: $e");
      return {};
    }
  }

  Future<void> addDanceForAdmin({
    required String adminId,
    required String danceId,
    required Map<String, dynamic> danceData,
  }) async {
    await _dbRef.child('admins').child(adminId).child('dances').child(danceId).set(danceData);
  }

  Future<void> addShowForAdmin({
    required String adminId,
    required String showId,
    required Map<String, dynamic> showData,
  }) async {
    await _dbRef.child('admins').child(adminId).child('shows').child(showId).set(showData);
  }

  Future<void> saveCostume({
    required String adminId,
    required String costumeId,
    required Map<String, dynamic> costumeData,
  }) async {
    await _dbRef.child('admins').child(adminId).child('costumes').child(costumeId).set(costumeData);
  }

  Future<void> saveRepair({
    required String adminId,
    required String repairId,
    required Map<String, dynamic> repairData,
  }) async {
    await _dbRef.child('admins').child(adminId).child('repairs').child(repairId).set(repairData);
  }

  Future<void> saveCostumeItem({
    required String adminId,
    required String itemId,
    required Map<String, dynamic> itemData,
  }) async {
    await _dbRef.child('admins').child(adminId).child('costumeItems').child(itemId).set(itemData);
  }

  Future<void> saveIssueItem({
    required String adminId,
    required String issueId,
    required Map<String, dynamic> issueData,
  }) async {
    await _dbRef.child('admins').child(adminId).child('issueItems').child(issueId).set(issueData);
  }

  Future<Map<String, dynamic>> getCostumesForAdmin(String adminId) async {
    final snapshot = await _dbRef.child('admins').child(adminId).child('costumes').get();
    return snapshot.exists ? Map<String, dynamic>.from(snapshot.value as Map) : {};
  }

  Future<Map<String, dynamic>> getRepairsForAdmin(String adminId) async {
    final snapshot = await _dbRef.child('admins').child(adminId).child('repairs').get();
    return snapshot.exists ? Map<String, dynamic>.from(snapshot.value as Map) : {};
  }

  Future<Map<String, dynamic>> getCostumeItemsForAdmin(String adminId) async {
    final snapshot = await _dbRef.child('admins').child(adminId).child('costumeItems').get();
    return snapshot.exists ? Map<String, dynamic>.from(snapshot.value as Map) : {};
  }

  Future<Map<String, dynamic>> getIssueItemsForAdmin(String adminId) async {
    final snapshot = await _dbRef.child('admins').child(adminId).child('issueItems').get();
    return snapshot.exists ? Map<String, dynamic>.from(snapshot.value as Map) : {};
  }

  Future<void> updateUsername({required String username}) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _dbRef.child('users').child(user.uid).update({
        'username': username,
      });
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
    }) async {
      try {
        UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );  

        final user = result.user;
        if (user == null) throw Exception("Firebase user is null");

        final snapshot = await _dbRef.child('users').child(user.uid).get();

        if (!snapshot.exists || snapshot.value == null) {
          throw Exception("User data not found in database");
        }

        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data['id'] = user.uid;
        return AppUser.fromJson(data);
      } catch (e) {
        rethrow;
      }
    }

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
