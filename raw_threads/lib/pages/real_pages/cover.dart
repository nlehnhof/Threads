import 'package:flutter/widgets.dart';

class Cover extends StatelessWidget {
  const Cover({super.key});
  
  @override
  Widget build(BuildContext context) =>
  Container(
    width: 393,
    height: 852,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: Color(0xFF6A8071)),
    child: Stack(
        children: [
            Positioned(
                left: -960,
                top: -443,
                child: SizedBox(
                    width: 2347,
                    height: 1911,
                    child: Stack(
                        children: [
                            Positioned(
                                left: 128,
                                top: 471,
                                child: Opacity(
                                    opacity: 0.30,
                                    child: Container(
                                        width: 1385,
                                        height: 1385,
                                        decoration: ShapeDecoration(
                                            shape: OvalBorder(
                                                side: BorderSide(width: 2, color: Color(0xFFEBEFEE)),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                            Positioned(
                                left: 0,
                                top: 0,
                                child: Opacity(
                                    opacity: 0.30,
                                    child: Container(
                                        width: 1385,
                                        height: 1385,
                                        decoration: ShapeDecoration(
                                            shape: OvalBorder(
                                                side: BorderSide(width: 2, color: Color(0xFFEBEFEE)),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                            Positioned(
                                left: 950,
                                top: 208,
                                child: Opacity(
                                    opacity: 0.30,
                                    child: Container(
                                        width: 1369,
                                        height: 1369,
                                        decoration: ShapeDecoration(
                                            shape: OvalBorder(
                                                side: BorderSide(width: 2, color: Color(0xFFEBEFEE)),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                            Positioned(
                                left: 73,
                                top: 416,
                                child: Opacity(
                                    opacity: 0.30,
                                    child: Container(
                                        width: 1495,
                                        height: 1495,
                                        decoration: ShapeDecoration(
                                            shape: OvalBorder(
                                                side: BorderSide(width: 2, color: Color(0xFFEBEFEE)),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                            Positioned(
                                left: 922,
                                top: 180,
                                child: Opacity(
                                    opacity: 0.30,
                                    child: Container(
                                        width: 1425,
                                        height: 1425,
                                        decoration: ShapeDecoration(
                                            shape: OvalBorder(
                                                side: BorderSide(width: 2, color: Color(0xFFEBEFEE)),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        ],
    ),
  );
}