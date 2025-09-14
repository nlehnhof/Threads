import 'package:flutter/material.dart';
import 'sewing_animation.dart';

class CustomLoader extends StatelessWidget {
  const CustomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 120,
        width: 200,
        child: SewingAnimation(),
      ),
    );
  }
}
