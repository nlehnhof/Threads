import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/account/app_state.dart';
import 'package:raw_threads/pages/real_pages/home_page.dart';
import 'package:raw_threads/services/auth_service.dart';
import 'package:raw_threads/classes/style_classes/primary_button.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:firebase_database/firebase_database.dart';
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => isLoading = true);

    try {
      final appUser = await AuthService().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Ensure user record exists
      final userRef = FirebaseDatabase.instance.ref("users/${appUser.id}");
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        await userRef.set({
          "email": appUser.email,
          "role": "user", // default unless you assign admin manually
          "linkedAdminId": null,
        });
      }

      final appState = context.read<AppState>();
      await appState.initialize(uid: appUser.id);

      final role = appState.role;

      if (role == 'admin' || role == 'user') {
        if (!mounted) return;

        // Navigate to HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(role: role!)),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role not recognized')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.primary,
      appBar: AppBar(backgroundColor: myColors.primary),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Login',
              style: TextStyle(
                fontSize: 48,
                color: myColors.secondary,
                fontFamily: 'Vogun',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              style: TextStyle(color: myColors.secondary, backgroundColor: myColors.primary),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: myColors.secondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: myColors.secondary, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: myColors.secondary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              style: TextStyle(color: myColors.secondary, backgroundColor: myColors.primary),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: myColors.secondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: myColors.secondary, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: myColors.secondary, width: 2),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : PrimaryButton(
                      label: 'Login',
                      color: myColors.secondary,
                      color2: myColors.primary,
                      onPressed: _handleLogin,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
