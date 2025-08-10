import 'package:flutter/material.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/pages/real_pages/welcome_page.dart';
import 'package:raw_threads/sidebar/sidebar_item.dart';
import 'package:raw_threads/pages/real_pages/home_page.dart'; 
import 'package:raw_threads/pages/real_pages/new_inv_page.dart';
import 'package:raw_threads/pages/real_pages/repair_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Assuming you have a ProfilePage
import 'package:raw_threads/pages/real_pages/teams_page.dart'; // Assuming you have a TeamPage

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
            // Close (X) button in the top right
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 16),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(
                    Icons.close, 
                    color: Colors.white, 
                    size: 35,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the drawer
                  },
                ),
              ),
            ),

            const SizedBox(height: 55), // Optional top spacing

            // Top section: Home, Inventory, Repairs, Teams, Chats (with 16 height spacing)
            ...[
              SidebarItem(destinationBuilder: () => HomePage(role: role), label: 'Home'),
              SidebarItem(destinationBuilder: () => DanceInventoryPage(role: role), label: 'Dance Inventory'),
              SidebarItem(destinationBuilder: () => RepairPage(role), label: 'Repairs'),
              SidebarItem(destinationBuilder: () => TeamsPage(), label: 'Teams'),
            ].expand((item) => [
              item,
              const SizedBox(height: 10), // 16px space between items
            ]).toList()
              ..removeLast(), // remove final spacer

            const Spacer(), // Push the next section to the bottom

            // SidebarItem(destinationBuilder: () => const ProfilePage(), label: 'Profile'),
            SidebarItem(destinationBuilder: () => 
                AlertDialog(
                  backgroundColor: myColors.primary,
                  title: Text('Logout?', style: TextStyle(fontFamily: 'Vogun', fontSize: 24, color: myColors.secondary)),
                  actions: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context); // close dialog first
                            // Add sign out here if using Firebase Auth
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => WelcomePage()),
                            );
                          },
                          child: Text(
                            'Logout',
                            style: TextStyle(fontSize: 18, color: myColors.secondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(fontSize: 18, color: Colors.red)),
                          ),
                      ],
                    ),
                  ],
                  ), 
                  label: 'Logout'),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
