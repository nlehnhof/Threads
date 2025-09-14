import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final Color color;
  final Color color2;
  final Color? border; // make nullable

  const PrimaryButton({
    super.key,
    required this.label,
    required this.color,
    required this.color2,
    this.onPressed,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 358,
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: border != null ? Border.all(color: border!, width: 2) : null,
        ),
        child: Center(
          child: SizedBox(
            width: 310,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color2,
                fontSize: 17,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
