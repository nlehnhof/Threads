import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:raw_threads/classes/main_classes/app_user.dart';
import 'package:raw_threads/pages/profile_builds/edit_profile.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  final String role;
  const ProfilePage({super.key, required this.role});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppUser? user;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (currentUser == null) return;
    
    // Load from database
    final snapshot = await FirebaseDatabase.instance.ref('users/${currentUser!.uid}').get();
    if (snapshot.exists) {
      final loadedUser = AppUser.fromJson(Map<String, dynamic>.from(snapshot.value as Map));

      // Load photo path from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final localPhotoPath = prefs.getString('profile_photo_path');

      // Create a new AppUser instance with updated photoURL
      final userWithPhoto = loadedUser.copyWith(
        photoURL: localPhotoPath ?? loadedUser.photoURL,
      );

      setState(() {
        user = userWithPhoto;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        backgroundColor: myColors.primary,
        title: Text('Profile', style: TextStyle(fontFamily: 'Vogun', fontSize: 28, color: myColors.secondary)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfilePage(user: user!)),
              );
              await _loadUser(); // reload after edit
            },
            child: const Text(
              'Edit',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: user!.photoURL != null ? (user!.photoURL!.startsWith('http') ? NetworkImage(user!.photoURL!) : FileImage(File(user!.photoURL!)) as ImageProvider) : null,
              child: user!.photoURL == null ? const Icon(Icons.person, size: 50) : null,
            ),
            const SizedBox(height: 16),
            Text(user!.username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(user!.email),
            if (user!.phoneNumber != null) Text(user!.phoneNumber!),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Sizes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: user!.sizes.isEmpty
                  ? const Text("No sizes added yet.")
                  : ListView(
                      children: user!.sizes.entries.map((entry) {
                        return ListTile(
                          title: Text(entry.key),
                          trailing: Text(entry.value),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
