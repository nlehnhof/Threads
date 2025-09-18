import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/pages/real_pages/home_page.dart';
import 'package:raw_threads/pages/real_pages/new_inv_page.dart';
import 'package:raw_threads/pages/real_pages/repair_page.dart';
import 'package:raw_threads/pages/real_pages/profile_page.dart';
import 'package:raw_threads/pages/real_pages/teams_page.dart';
import 'package:raw_threads/pages/real_pages/welcome_page.dart';
import 'package:raw_threads/services/auth_service.dart';
import 'package:raw_threads/sidebar/sidebar_item.dart';

class Sidebar extends StatelessWidget {
  final String role;
  const Sidebar({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF6A8071),
      child: SafeArea(
        child: Column(
          children: [
            // Close button
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 16),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 35),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            const SizedBox(height: 55),

            // Top section items
            ...[
              SidebarItem(
                  destinationBuilder: () => HomePage(role: role),
                  image: 'assets/home.png'),
              SidebarItem(
                  destinationBuilder: () => DanceInventoryPage(role: role),
                  image: 'assets/inventory.png'),
              SidebarItem(
                  destinationBuilder: () => RepairPage(role: role),
                  image: 'assets/repairs.png'),
              SidebarItem(
                  destinationBuilder: () => TeamsPage(role: role),
                  image: 'assets/teams.png'),
            ].expand((item) => [
                  item,
                  const SizedBox(height: 10),
                ]).toList()
              ..removeLast(),

            const Spacer(),

            // Bottom section
            SidebarItem(
                destinationBuilder: () => ProfilePage(),
                image: 'assets/profile.png'),
            const SizedBox(height: 10),

            // Settings / Logout
            SidebarItem(
              image: 'assets/settings.png',
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: myColors.primary,
                    title: Text(
                      'Logout?',
                      style: TextStyle(
                        fontFamily: 'Vogun',
                        fontSize: 24,
                        color: myColors.secondary,
                      ),
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                  fontSize: 18, color: myColors.secondary),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 18, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                try {
                  // 1️⃣ Sign out from Firebase
                  await authService.value.signOut();
                  // 3️⃣ Close the drawer
                  Navigator.pop(context);

                  // 4️⃣ Navigate directly to WelcomePage
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomePage()),
                    (route) => false,
                  );
                } catch (e) {
                  debugPrint('Logout failed: $e');
                }
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
