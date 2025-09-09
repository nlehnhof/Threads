import 'package:flutter/material.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/classes/main_classes/app_user.dart';
import 'package:firebase_database/firebase_database.dart';

class MemberProfile extends StatelessWidget {
  final String userId;
  const MemberProfile({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        backgroundColor: myColors.primary,
        title: Text(
          'Member Profile',
          style: TextStyle(
            fontFamily: 'Vogun',
            fontSize: 28,
            color: myColors.secondary,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('users/$userId').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("User not found."));
          }

          final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );
          final user = AppUser.fromJson(data);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.username,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(user.email),
                if (user.phoneNumber != null) Text(user.phoneNumber!),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sizes',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: user.sizes.isEmpty
                      ? const Text("No sizes added yet.")
                      : ListView(
                          children: user.sizes.entries.map((entry) {
                            return ListTile(
                              title: Text(entry.key),
                              trailing: Text(entry.value),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
