import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raw_threads/services/auth_service.dart';
import 'package:raw_threads/home/home_page.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:raw_threads/firebase_options.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
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
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await authService.value.createAccount(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );
                  await authService.value.updateUsername(
                    username: _usernameController.text,
                  );
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}