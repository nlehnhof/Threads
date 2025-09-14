import 'dart:math';
import 'package:flutter/material.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';

class SewingAnimation extends StatefulWidget {
  const SewingAnimation({super.key});

  @override
  State<SewingAnimation> createState() => _SewingAnimationState();
}

class _SewingAnimationState extends State<SewingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(); // Loop forever
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final needleX = width * _controller.value;
        final time = _controller.value * 2 * pi * 4; // thread wriggle speed

        // Needle bobbing up and down (like piercing fabric)
        final bob = sin(_controller.value * 2 * pi * 6) * 20;

        return Stack(
          children: [
            SizedBox.expand(
              child: CustomPaint(
                painter: ThreadPainter(needleX, time),
              ),
            ),
            Positioned(
              left: needleX,
              top: height / 2 - 30 + bob,
              child: Image.asset(
                'assets/needle.png',
                width: 40,
              ),
            ),
          ],
        );
      },
    );
  }
}

class ThreadPainter extends CustomPainter {
  final double needleX;
  final double time;

  ThreadPainter(this.needleX, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = myColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (double x = 0; x < needleX; x += 5) {
      double y = size.height / 2 + 20 * sin((x / 30) * 2 * pi + time);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ThreadPainter oldDelegate) {
    return oldDelegate.needleX != needleX || oldDelegate.time != time;
  }
}
