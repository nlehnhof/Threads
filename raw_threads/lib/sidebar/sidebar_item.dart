import 'package:flutter/material.dart';

class SidebarItem extends StatelessWidget {
  final Widget Function()? destinationBuilder;
  final VoidCallback? onTap;
  final String image;

  const SidebarItem({
    super.key,
    this.destinationBuilder,
    this.onTap,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: onTap ??
            () {
              if (destinationBuilder != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => destinationBuilder!()),
                );
              }
            },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 200,
          ),
          child: Image.asset(
            image,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
