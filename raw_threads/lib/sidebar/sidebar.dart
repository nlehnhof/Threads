import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raw_threads/account/app_state.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/pages/real_pages/home_page.dart';
import 'package:raw_threads/pages/real_pages/new_inv_page.dart';
import 'package:raw_threads/pages/real_pages/repair_page.dart';
import 'package:raw_threads/pages/real_pages/profile_page.dart';
import 'package:raw_threads/pages/real_pages/teams_page.dart';
import 'package:raw_threads/sidebar/sidebar_item.dart';
import 'package:provider/provider.dart';

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
                destinationBuilder: () => ProfilePage(role: role),
                image: 'assets/profile.png'),
            const SizedBox(height: 10),
            SidebarItem(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: myColors.primary,
                    title: Text(
                      'Logout?',
                      style: TextStyle(
                          fontFamily: 'Vogun',
                          fontSize: 24,
                          color: myColors.secondary),
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context); // close dialog
                              await FirebaseAuth.instance.signOut();
                              context.read<AppState>().reset();
                            },
                            child: Text(
                              'Logout',
                              style: TextStyle(fontSize: 18, color: myColors.secondary),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child:
                                const Text('Cancel', style: TextStyle(fontSize: 18, color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              image: 'assets/settings.png',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
