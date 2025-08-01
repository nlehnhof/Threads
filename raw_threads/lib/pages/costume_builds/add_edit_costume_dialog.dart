import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart'; // Ensure this exists

class AddEditCostumeDialog extends StatefulWidget {
  final CostumePiece? existing;
  final bool allowDelete;

  const AddEditCostumeDialog({super.key, this.existing, this.allowDelete = false});

  @override
  State<AddEditCostumeDialog> createState() => _AddEditCostumeDialogState();
}

class _AddEditCostumeDialogState extends State<AddEditCostumeDialog> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController cleanUpController = TextEditingController();
  final TextEditingController careController = TextEditingController();
  final TextEditingController turnInController = TextEditingController();
  final TextEditingController availableController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  File? image;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final existing = widget.existing!;
      titleController.text = existing.title;
      cleanUpController.text = existing.cleanUp;
      careController.text = existing.care;
      turnInController.text = existing.turnIn;
      availableController.text = existing.available;
      totalController.text = existing.total;
      image = existing.image;
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => image = File(picked.path));
    }
  }

  void _save() {
    if (titleController.text.trim().isEmpty) return;
    final piece = CostumePiece(
      title: titleController.text.trim(),
      cleanUp: cleanUpController.text.trim(),
      care: careController.text.trim(),
      turnIn: turnInController.text.trim(),
      available: availableController.text.trim(),
      total: totalController.text.trim(),
      image: image,
    );
    Navigator.of(context).pop(piece);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Costume?'),
        content: const Text('Are you sure you want to delete this costume piece?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context)
              ..pop()
              ..pop(null),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Costume' : 'Add Costume'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: image != null
                  ? Image.file(image!, height: 150)
                  : Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 50),
                    ),
            ),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: cleanUpController, decoration: const InputDecoration(labelText: 'Clean-up')),
            TextField(controller: careController, decoration: const InputDecoration(labelText: 'Care')),
            TextField(controller: turnInController, decoration: const InputDecoration(labelText: 'Turn-in')),
            TextField(controller: availableController, decoration: const InputDecoration(labelText: 'Available')),
            TextField(controller: totalController, decoration: const InputDecoration(labelText: 'Total')),
          ],
        ),
      ),
      actions: [
        if (widget.allowDelete)
          TextButton(
            onPressed: _delete,
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
