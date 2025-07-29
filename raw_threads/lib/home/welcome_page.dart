import 'package:flutter/material.dart';
import 'package:raw_threads/home/home_page.dart';
import 'package:raw_threads/login/login_page.dart';
import 'package:raw_threads/login/signup_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
              },
              child: const Text('Login'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage()));
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}