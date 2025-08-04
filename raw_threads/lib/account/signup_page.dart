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
    _usernameController.dispose();
    super.dispose();
  }

  Widget _buildRoleButton(String label, int index) {
    final selected = isSelected[index];
    return GestureDetector(
      onTap: () {
        setState(() {
          for (int i = 0; i < isSelected.length; i++) {
            isSelected[i] = i == index;
          }
        });
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? myColors.secondary : myColors.primary,
          border: Border.all(color: myColors.secondary, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? myColors.primary : myColors.secondary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.primary,
      appBar: AppBar(backgroundColor: myColors.primary, iconTheme: IconThemeData(color: myColors.secondary),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Sign Up', style: TextStyle(fontSize: 48, color: myColors.secondary, fontFamily: 'Vogun', fontWeight: FontWeight.w500)),
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
            TextField(
              controller: _usernameController,
              style: TextStyle(
                color: myColors.secondary, 
                backgroundColor: myColors.primary,
                ),
              decoration: InputDecoration(
                labelText: 'Username', 
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRoleButton('User', 0),
                _buildRoleButton('Admin', 1),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 20),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : PrimaryButton(
                    label: 'Sign Up',
                    color: myColors.secondary,
                    color2: myColors.primary,
                    onPressed: () async {
                      final localContext = context;
                      setState(() {
                        isLoading = true;
                      });
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