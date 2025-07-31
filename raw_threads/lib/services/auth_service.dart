import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Create a new user and store their email and role
  Future<void> createAccount({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await _dbRef.child('users').child(user.uid).set({
          'email': email,
          'role': role,
          'username': '', // Will be updated later
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update username for the current user
  Future<void> updateUsername({required String username}) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _dbRef.child('users').child(user.uid).update({
        'username': username,
      });
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Get the current user's role
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

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
