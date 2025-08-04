import 'package:flutter/material.dart';
import 'package:raw_threads/services/auth_service.dart';
import 'package:raw_threads/pages/real_pages/home_page.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:raw_threads/firebase_options.dart';
import 'package:raw_threads/classes/style_classes/primary_button.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  List<bool> isSelected = [true, false];

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
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            ToggleButtons(
              isSelected: isSelected,
              onPressed: (int index) {
                setState(() {
                  for (int i = 0; i < isSelected.length; i++) {
                    isSelected[i] = i == index;
                  }
                });
              },
              children: const <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('User'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Admin'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 20),
              child: PrimaryButton(
                label: 'Sign Up',
                color: myColors.primary,
                color2: myColors.secondary,
                onPressed: () async {

                  final localContext = context;

                  try {
                    String selectedRole = isSelected[0] ? 'user' : 'admin';

                    await authService.value.createAccount(
                      email: _emailController.text,
                      password: _passwordController.text,
                      role: selectedRole,
                    );
                    await authService.value.updateUsername(
                      username: _usernameController.text,
                    );

                    if (!localContext.mounted) return;  
                    Navigator.pushReplacement(localContext, MaterialPageRoute(builder: (_) => HomePage(role: selectedRole)));
                  } catch (e) {
                    ScaffoldMessenger.of(localContext).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}