import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raw_threads/classes/main_classes/app_user.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raw_threads/services/storage_service.dart';

class EditProfilePage extends StatefulWidget {
  final AppUser user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  File? _photo;
  String? _photoUrl;

  // Use a list of items with persistent controllers (avoid creating controllers in build).
  final List<_SizeItem> _sizeItems = [];

  @override
  void initState() {
    super.initState();
    usernameController.text = widget.user.username;
    phoneController.text = widget.user.phoneNumber ?? '';

    // Initialize size items from the user's sizes map
    if (widget.user.sizes.isNotEmpty) {
      widget.user.sizes.forEach((title, size) {
        _sizeItems.add(_SizeItem(title: title, value: size));
      });
    }
    _photoUrl = widget.user.photoURL;
  }

  @override
  void dispose() {
    usernameController.dispose();
    phoneController.dispose();
    for (final item in _sizeItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> pickImage() async {
    // Pick and upload using StorageHelper
    final userId = currentUser!.uid; // example: store under "users/$uid"
    final uploadedUrl = await StorageHelper.pickAndUploadImage(
      storagePath: 'users/$userId/',
      fromCamera: false,
    );

    if (uploadedUrl != null) {
      setState(() {
        _photoUrl = uploadedUrl;
        _photo = null; // we now use URL instead of local file
      });

      // Save locally too if needed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_path', uploadedUrl);
    }
  }


  void _addSize() {
    setState(() {
      // Add one new item (two input fields will appear: Title + Size)
      _sizeItems.add(_SizeItem(title: '', value: ''));
    });
  }

  Future<void> _saveProfile() async {
    if (currentUser == null) return;
    final userRef = FirebaseDatabase.instance.ref('users/${currentUser!.uid}');

    // Build sizes map from current items (skip empty titles)
    final Map<String, String> sizesToSave = {};
    for (final item in _sizeItems) {
      final title = item.titleController.text.trim();
      final value = item.valueController.text.trim();
      if (title.isNotEmpty) sizesToSave[title] = value;
    }

    // Prepare update map — only the fields that changed
    final Map<String, Object?> updates = {
      'username': usernameController.text.trim(),
      'phoneNumber': phoneController.text.trim(),
      'sizes': sizesToSave,
    };

    if (_photoUrl != null) updates['photoUrl'] = _photoUrl; 

    try {
      // Use update() to avoid wiping out other fields (like adminLinkedId)
      await userRef.update(updates);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      // handle save error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    }
  }

  void _removeSizeAt(int index) {
    setState(() {
      _sizeItems[index].dispose();
      _sizeItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Vogun',
            fontSize: 28,
            color: myColors.secondary,
          ),
        ),
        backgroundColor: myColors.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _photo != null
                    ? FileImage(_photo!)
                    : (_photoUrl != null
                        ? NetworkImage(_photoUrl!)
                        : null) as ImageProvider?,
                child: (_photo == null && _photoUrl == null)
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Sizes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            // Build size rows from _sizeItems (controllers are persistent)
            ..._sizeItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: item.titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: item.valueController,
                        decoration: const InputDecoration(labelText: 'Size'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeSizeAt(index),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _addSize, child: const Text('Add Size')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveProfile, child: const Text('Save Changes')),
          ],
        ),
      ),
    );
  }
}

// Helper class to hold controllers per size row
class _SizeItem {
  final TextEditingController titleController;
  final TextEditingController valueController;

  _SizeItem({String? title, String? value})
      : titleController = TextEditingController(text: title ?? ''),
        valueController = TextEditingController(text: value ?? '');

  void dispose() {
    titleController.dispose();
    valueController.dispose();
  }
}
