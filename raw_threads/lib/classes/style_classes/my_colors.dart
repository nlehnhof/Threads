import 'package:flutter/material.dart';

class MyColors {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color hover;
  final Color click;
  final Color disabled;
  final Color selected;
  final Color completed;

  const MyColors({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.hover,
    required this.click,
    required this.disabled,
    required this.selected,
    required this.completed,
  });
}

// Create a global instance
const myColors = MyColors(
  primary: Color(0xFF6A8071),
  secondary: Color(0xFFEBEFEE),
  tertiary: Color(0xFFFBBC05),
  selected: Color.fromARGB(134, 62, 119, 80),
  hover: Color(0xFFD4DAD8),
  click: Color(0x33191B1A),
  disabled: Color(0xFFC8CEC9),
  completed: Color.fromARGB(135, 90, 118, 91),
);
