import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:uuid/uuid.dart';
import 'package:raw_threads/services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEditCostumeDialog extends StatefulWidget {
  final CostumePiece? existing;
  final bool allowDelete;
  final Function(CostumePiece) onSave;
  final String role;
  final String danceId;
  final String gender;

  const AddEditCostumeDialog({
    super.key,
    this.existing,
    required this.allowDelete,
    required this.onSave,
    required this.role,
    required this.danceId,
    required this.gender,
  });

  @override
  State<AddEditCostumeDialog> createState() => _AddEditCostumeDialogState();
}

class _AddEditCostumeDialogState extends State<AddEditCostumeDialog> {
  final ImagePicker _picker = ImagePicker();
  final uuid = Uuid();
  final currentUser = FirebaseAuth.instance.currentUser;

  File? _pickedImageFile;
  String? _imageUrl; // URL in Firebase Storage

  late TextEditingController _titleController;
  late TextEditingController _careController;
  late TextEditingController _turnInController;
  late TextEditingController _availableController;
  late TextEditingController _totalController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _imageUrl = existing?.imagePath; // assume existing path is URL if previously uploaded

    _titleController = TextEditingController(text: existing?.title ?? '');
    _careController = TextEditingController(text: existing?.care ?? '');
    _turnInController = TextEditingController(text: existing?.turnIn ?? '');
    _availableController = TextEditingController(text: existing?.available.toString());
    _totalController = TextEditingController(text: existing?.total.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _careController.dispose();
    _turnInController.dispose();
    _availableController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (currentUser == null) return;

    final uploadedUrl = await StorageHelper.pickAndUploadImage(
      storagePath: 'admins/${currentUser!.uid}/dances/${widget.danceId}/costumes/${widget.gender}/',
      fromCamera: false,
    );

    if (uploadedUrl != null) {
      setState(() {
        _imageUrl = uploadedUrl;
        _pickedImageFile = null; // we now use URL instead of local file
      });
    }
  }

  void _onSavePressed() {
    final title = _titleController.text.trim();
    final care = _careController.text.trim();
    final turnIn = _turnInController.text.trim();
    final available = int.tryParse(_availableController.text.trim()) ?? 0;
    final total = int.tryParse(_totalController.text.trim()) ?? 0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    if (_imageUrl == null || _imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    final newPiece = CostumePiece(
      id: widget.existing?.id ?? uuid.v4(),
      title: title,
      care: care,
      turnIn: turnIn,
      available: available,
      total: total,
      imagePath: _imageUrl, // now storing URL
    );

    widget.onSave(newPiece);
  }

  Widget _buildImageWidget() {
    if (_pickedImageFile != null) {
      return Image.file(_pickedImageFile!, height: 150, fit: BoxFit.cover);
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Image.network(_imageUrl!, height: 150, fit: BoxFit.cover);
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() {
    return Container(
      height: 150,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Costume Piece' : 'Edit Costume Piece'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _buildImageWidget(),
            ),
            const SizedBox(height: 6),
            const Text('Tap image to select from gallery'),
            const SizedBox(height: 12),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: _careController, decoration: const InputDecoration(labelText: 'Care')),
            TextField(controller: _turnInController, decoration: const InputDecoration(labelText: 'Turn In')),
            TextField(
              controller: _availableController,
              decoration: const InputDecoration(labelText: 'Available'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _totalController,
              decoration: const InputDecoration(labelText: 'Total'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        if (widget.allowDelete)
          TextButton(
            onPressed: () => Navigator.of(context).pop(null), // signal delete
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(onPressed: _onSavePressed, child: const Text('Save')),
      ],
    );
  }
}
