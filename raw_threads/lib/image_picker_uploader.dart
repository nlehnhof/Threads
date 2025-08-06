import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

typedef OnImagePicked = void Function(File? imageFile);

class LocalImagePicker extends StatefulWidget {
  final String? initialFilePath; // Local file path if you already have one
  final OnImagePicked onImagePicked;

  const LocalImagePicker({
    super.key,
    this.initialFilePath,
    required this.onImagePicked,
  });

  @override
  State<LocalImagePicker> createState() => _LocalImagePickerState();
}

class _LocalImagePickerState extends State<LocalImagePicker> {
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilePath != null && widget.initialFilePath!.isNotEmpty) {
      _imageFile = File(widget.initialFilePath!);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() => _imageFile = file);
    widget.onImagePicked(file);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: 150,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          image: _imageFile != null
              ? DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _imageFile == null
            ? const Center(
                child: Icon(Icons.image_outlined, size: 50, color: Colors.grey),
              )
            : null,
      ),
    );
  }
}
