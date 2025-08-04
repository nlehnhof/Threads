import 'dart:io';
import 'package:flutter/material.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/pages/costume_builds/costume_page.dart';
import 'package:raw_threads/services/dance_inventory_service.dart'; // ✅ Import your service

class GenericDancePage extends StatefulWidget {
  final String role;
  final Dances dance;
  final void Function(Dances) onDelete; // Called in parent page to update UI

  const GenericDancePage({
    super.key,
    required this.role,
    required this.dance,
    required this.onDelete,
  });

  @override
  State<GenericDancePage> createState() => _GenericDancePageState();
}

class _GenericDancePageState extends State<GenericDancePage> {
  late String role;
  late Dances dance; 
  late void Function(Dances) onDelete;
  bool isAdmin = true;

  ImageProvider? _buildImage(String? path) {
    if (path == null) return null;
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    
    if (role == 'admin') {
      isAdmin;
    } else {
      isAdmin = false;
    }

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: myColors.secondary,
        title: Text(
          dance.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontFamily: 'Raleway',
          ),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              tooltip: 'Delete Dance',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Dance?'),
                    content: Text('Are you sure you want to delete "${dance.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop(); // Close dialog
                          await DanceInventoryService.instance.delete(dance.id); // Delete from storage
                            onDelete(dance); // Update parent UI
                          if (!context.mounted) return;
                          Navigator.of(context).pop(); // Close this page
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontFamily: 'Raleway',
                ),
              ),
            ),
          ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildImageCard(dance.leftImagePath),
                const SizedBox(width: 4.0),
                _buildImageCard(dance.rightImagePath),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoText(dance.title, fontSize: 22, isBold: true),
            const SizedBox(height: 4),
            _buildInfoText(dance.country),
            const SizedBox(height: 4),
            _buildInfoText(dance.category.name),
            const SizedBox(height: 24),
            _buildButton(context, 'Men'),
            const SizedBox(height: 12),
            _buildButton(context, 'Women'),
            const Spacer(),
            if (isAdmin)
              SizedBox(
                width: 337,
                height: 60,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: myColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Assign to Team'),
                ),
              ),
            const SizedBox(height: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String? imagePath) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 170.5,
        height: 325,
        decoration: BoxDecoration(
          color: const Color(0xFFFEFEFE),
          borderRadius: BorderRadius.circular(16),
          image: _buildImage(imagePath) != null
              ? DecorationImage(
                  image: _buildImage(imagePath)!,
                  fit: BoxFit.cover,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildInfoText(String text, {double fontSize = 15, bool isBold = false}) {
    return Container(
      width: 337,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Raleway',
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
          color: const Color(0xFF191B1A),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label) {
    return SizedBox(
      width: 337,
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CostumePage(
                role: role,
                dance: dance,
                gender: label,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: myColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
