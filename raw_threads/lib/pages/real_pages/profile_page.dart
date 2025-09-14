import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:raw_threads/classes/main_classes/app_user.dart';
import 'package:raw_threads/pages/profile_builds/edit_profile.dart'; // adjust import if needed
import 'package:raw_threads/classes/style_classes/my_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot =
        await FirebaseDatabase.instance.ref("users/${currentUser.uid}").get();

    if (snapshot.exists) {
      setState(() {
        _user = AppUser.fromJson(
          Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>),
        );
        _loading = false;
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_user == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(user: _user!),
      ),
    );

    // 🔄 Reload user after coming back
    await _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return const Center(child: Text("No user data found."));
    }

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        title: Text("Profile", style: 
        TextStyle(color: myColors.secondary, fontFamily: "Vogun", fontSize: 28)),
        centerTitle: true,
        iconTheme: IconThemeData(color: myColors.secondary),
        backgroundColor: myColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _user!.photoURL != null
                  ? NetworkImage(_user!.photoURL!)
                  : null,
              child: _user!.photoURL == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              _user!.username,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (_user!.phoneNumber != null &&
                _user!.phoneNumber!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text("Phone: ${_user!.phoneNumber}"),
            ],
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Sizes:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ..._user!.sizes.entries.map(
              (e) => ListTile(
                title: Text(e.key),
                trailing: Text(e.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
