import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:raw_threads/firebase_options.dart';
import 'package:raw_threads/services/auth_service.dart';
import 'package:raw_threads/pages/real_pages/home_page.dart';
import 'package:raw_threads/classes/style_classes/primary_button.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';

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
      backgroundColor: myColors.primary,
      appBar: AppBar(
        backgroundColor: myColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Login', style: TextStyle(fontSize: 48, color: myColors.secondary, fontFamily: 'Vogun', fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              style: TextStyle(
                color: myColors.secondary, 
                backgroundColor: myColors.primary,
                ),
              decoration: InputDecoration(
                labelText: 'Email', 
                labelStyle: TextStyle(color: myColors.secondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0), 
                  borderSide: BorderSide(
                    color: myColors.secondary, 
                    width: 2,
                    ),
                  ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: myColors.secondary, 
                    width: 2,
                    ),
                  ), 
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              style: TextStyle(
                color: myColors.secondary, 
                backgroundColor: myColors.primary,
                ),
              decoration: InputDecoration(
                labelText: 'Password', 
                labelStyle: TextStyle(color: myColors.secondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0), 
                  borderSide: BorderSide(
                    color: myColors.secondary, 
                    width: 2,
                    ),
                  ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: myColors.secondary, 
                    width: 2,
                    ),
                  ), 
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 20),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : PrimaryButton(
                      label: 'Login',
                      color: myColors.secondary,
                      color2: myColors.primary,
                      onPressed: () async {
                        final localContext = context;
                        setState(() {
                          isLoading = true;
                        });
                        try {
                          await AuthService().signIn(
                            email: _emailController.text,
                            password: _passwordController.text,
                          );
                          String? role = await AuthService().getRole();
                          
                          if (!localContext.mounted) return;

                          if (role == 'admin') {
                            Navigator.pushReplacement(localContext, MaterialPageRoute(builder: (_) => const HomePage(role: 'admin')));
                          } else if (role == 'user') {
                            Navigator.pushReplacement(localContext, MaterialPageRoute(builder: (_) => const HomePage(role: 'user')));
                          } else {
                            ScaffoldMessenger.of(localContext).showSnackBar(const SnackBar(content: Text('Role not recognized')));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(localContext).showSnackBar(SnackBar(content: Text('Error: $e')));
                        } finally {
                          if (mounted) {
                            setState(() {
                              isLoading = false;
                           });
                          }
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