import 'package:flutter/material.dart';
import 'package:raw_threads/account/login_page.dart';
import 'package:raw_threads/account/signup_page.dart';
import 'package:raw_threads/classes/style_classes/primary_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A8071),
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                    image: AssetImage("assets/threadline_logo.png"), 
                    alignment: Alignment.center, 
                    width: 63.15, 
                    height: 93.80,
                  ),
                  SizedBox(height: 10),
                  Text(
                  'Threadline',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFEFEFE),
                    fontSize: 34,
                    fontFamily: 'Vogun',
                    fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Center(
                child: PrimaryButton(
                  label: 'Log In',
                  color: Colors.white,
                  color2: Color(0xFF6A8071),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: PrimaryButton(
                  label: 'Sign Up',
                  color: Color(0xFF6A8071),
                  color2: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignUpPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 40), // Spacing from bottom if needed
        ],
      ),
    );
  }
}