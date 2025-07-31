import 'package:flutter/material.dart';

class HomePage extends StatefulWidget{
  final String role;
  const HomePage({super.key, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          Text('Welcome, ${widget.role}!'),
          const SizedBox(height: 20),
          // Display different content based on user role
          if (widget.role == 'admin') ...[
            Text('Admin Dashboard'),
            ElevatedButton(
              onPressed: () {
                // Navigate to admin-specific page
              },
              child: const Text('Go to Admin Page'),
            ),
          ] else if (widget.role == 'user') ...[
            Text('User Dashboard'),
            ElevatedButton(
              onPressed: () {
                // Navigate to user-specific page
              },
              child: const Text('Go to User Page'),
            ),
          ] else ...[
            Text('General Home Page'),
          ],
        ],
      ),
    );
  }
} 