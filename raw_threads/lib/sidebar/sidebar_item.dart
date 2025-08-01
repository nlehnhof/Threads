import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class SidebarItem extends StatelessWidget {
  const SidebarItem({super.key, required this.destinationBuilder, required this.label});

  final Widget Function() destinationBuilder;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destinationBuilder()),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DottedBorder(
              borderType: BorderType.RRect,
              radius: Radius.circular(0.5),
              dashPattern: [3, 3],
              color: Colors.white,
              strokeWidth: 1.2,
              child: SizedBox(
                height: 14,
                width: 14,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFEFEFE),
                fontSize: 17,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
