import 'package:flutter/material.dart';

class LinkAdminPage extends StatelessWidget {
  const LinkAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Link to Admin")),
      body: const Center(
        child: Text("Please link your account to an Admin."),
      ),
    );
  }
}
