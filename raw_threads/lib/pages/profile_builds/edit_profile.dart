import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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

  final List<_SizeItem> _sizeItems = [];

  @override
  void initState() {
    super.initState();
    usernameController.text = widget.user.username;
    phoneController.text = widget.user.phoneNumber ?? '';

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

  Future<void> _showPickImageOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(fromCamera: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(fromCamera: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage({required bool fromCamera}) async {
    if (currentUser == null) return;
    final userId = currentUser!.uid;
    final storagePath = 'users/$userId/profile_photos';

    final uploadedUrl = await StorageHelper.pickUploadAndReturnUrl(
      storagePath: storagePath,
      fromCamera: fromCamera,
    );

    if (uploadedUrl != null) {
      setState(() {
        _photoUrl = uploadedUrl;
        _photo = null;
      });

      // optional: cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_path', uploadedUrl);
    }
  }

  void _addSize() {
    setState(() {
      _sizeItems.add(_SizeItem(title: '', value: ''));
    });
  }

  Future<void> _saveProfile() async {
    if (currentUser == null) return;
    final userRef = FirebaseDatabase.instance.ref('users/${currentUser!.uid}');

    final Map<String, String> sizesToSave = {};
    for (final item in _sizeItems) {
      final title = item.titleController.text.trim();
      final value = item.valueController.text.trim();
      if (title.isNotEmpty) sizesToSave[title] = value;
    }

    final Map<String, Object?> updates = {
      'username': usernameController.text.trim(),
      'phoneNumber': phoneController.text.trim(),
      'sizes': sizesToSave,
    };

    if (_photoUrl != null) updates['photoURL'] = _photoUrl; // FIX ✅

    try {
      await userRef.update(updates);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
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
        iconTheme: IconThemeData(color: myColors.secondary),
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
              onTap: _showPickImageOptions,
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
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Sizes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

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
            }),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _addSize, child: const Text('Add Size')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

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
