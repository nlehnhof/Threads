import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raw_threads/classes/main_classes/app_user.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Map<String, String> sizesMap = {}; // title -> size

  @override
  void initState() {
    super.initState();
    usernameController.text = widget.user.username;
    phoneController.text = widget.user.phoneNumber ?? '';
    sizesMap = Map.from(widget.user.sizes);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Image Source"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.camera), child: const Text("Camera")),
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.gallery), child: const Text("Gallery")),
        ],
      ),
    );

    if (source == null) return;

    final file = await picker.pickImage(source: source);
    if (file != null) {
      setState(() => _photo = File(file.path));
    }
  }

  Future<void> _saveProfile() async {
    if (currentUser == null) return;
    final userRef = FirebaseDatabase.instance.ref('users/${currentUser!.uid}');

    String? photoPath = _photo != null ? _photo!.path : widget.user.photoURL;

    final updatedUser = widget.user.copyWith(
      username: usernameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      photoURL: photoPath,
      sizes: sizesMap,
    );

    await userRef.set(updatedUser.toJson());
    final prefs = await SharedPreferences.getInstance();
    if (_photo != null) {
      await prefs.setString('profile_photo_path', _photo!.path);
    }

    if (context.mounted) Navigator.pop(context);
  }

  void _addSize() {
    setState(() {
      sizesMap[''] = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(title: Text('Edit Profile', style: TextStyle(fontFamily: 'Vogun', fontSize: 28, color: myColors.secondary)), backgroundColor: myColors.primary,),
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
                    : (widget.user.photoURL != null ? NetworkImage(widget.user.photoURL!) : null) as ImageProvider?,
                child: (_photo == null && widget.user.photoURL == null) ? const Icon(Icons.person, size: 50) : null,
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
            ...sizesMap.entries.map((entry) {
              final keyController = TextEditingController(text: entry.key);
              final valueController = TextEditingController(text: entry.value);

              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: keyController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      onChanged: (val) {
                        final oldValue = sizesMap.keys.firstWhere((k) => k == entry.key);
                        sizesMap.remove(oldValue);
                        sizesMap[val] = valueController.text;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: valueController,
                      decoration: const InputDecoration(labelText: 'Size'),
                      onChanged: (val) {
                        sizesMap[keyController.text] = val;
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        sizesMap.remove(keyController.text);
                      });
                    },
                  )
                ],
              );
            }),
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
