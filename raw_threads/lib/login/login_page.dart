import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:raw_threads/firebase_options.dart';
import 'package:raw_threads/services/auth_service.dart';
import 'package:raw_threads/home/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  isLoading = true;
                });
                try {
                  await authService.value.signIn(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );
                  String? role = await authService.value.getRole();
                  if (role == 'admin') {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage(role: 'admin')));
                  } else if (role == 'user') {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage(role: 'user')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role not recognized')));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
