import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

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
              // SidebarItem(destinationBuilder: () => HomePage(currentUser: currentUser), label: 'Home'),
              // SidebarItem(destinationBuilder: () => DanceInventoryPage(currentUser: currentUser), label: 'Dance Inventory'),
              // SidebarItem(destinationBuilder: () => RepairPage(currentUser: currentUser), label: 'Repairs'),
              // SidebarItem(destinationBuilder: () => TeamsPage(currentUser: currentUser), label: 'Teams'),
            ].expand((item) => [
              item,
              const SizedBox(height: 10), // 16px space between items
            ]).toList()
              ..removeLast(), // remove final spacer

            const Spacer(), // Push the next section to the bottom

            // Bottom section: Profile, Log Out (24px from bottom)
            // SidebarItem(destinationBuilder: () => const ProfilePage(), label: 'Profile'),
            // SidebarItem(destinationBuilder: () => const WelcomePage(), label: 'Log Out'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
