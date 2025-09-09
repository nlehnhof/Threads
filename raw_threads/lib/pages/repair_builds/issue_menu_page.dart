import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raw_threads/classes/main_classes/issues.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/providers/issues_provider.dart';
import 'package:raw_threads/account/app_state.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

final uuid = Uuid();

class IssueMenuPage extends StatefulWidget {
  const IssueMenuPage({super.key});

  @override
  State<IssueMenuPage> createState() => _IssueMenuPageState();
}

class _IssueMenuPageState extends State<IssueMenuPage> {
  final TextEditingController _titleController = TextEditingController();

  Future<String?> _uploadImage(File file) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      final storageRef = FirebaseStorage.instance
          .ref('admins/${currentUser.uid}/issues/${uuid.v4()}.jpg');

      final snapshot = await storageRef.putFile(file);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("Image upload failed: $e");
      return null;
    }
  }

  Future<void> _addIssue() async {
    final provider = context.read<IssuesProvider>();
    final picker = ImagePicker();

    // Select image source
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Image Source"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text("Camera"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text("Gallery"),
          ),
        ],
      ),
    );

    if (source == null) return;

    // Pick image
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    // Get title
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Issue Title"),
        content: TextField(controller: _titleController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _titleController.text.trim()),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty) return;

    // Upload image
    final uploadedUrl = await _uploadImage(File(picked.path));
    if (uploadedUrl == null) return;

    // Create issue
    final newIssue = Issues(
      id: uuid.v4(),
      title: title,
      image: uploadedUrl,
    );

    await provider.add(newIssue);
    _titleController.clear();
  }

  Future<void> _deleteIssue(String id) async {
    await context.read<IssuesProvider>().delete(id);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AppState>().role == 'admin';

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        backgroundColor: myColors.secondary,
        title: const Text(
          'Issue Menu',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontFamily: 'Vogun',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _addIssue,
              child: const Icon(Icons.add),
            )
          : null,
      body: Consumer<IssuesProvider>(
        builder: (_, provider, __) {
          final issues = provider.allIssues;

          if (issues.isEmpty) {
            return const Center(child: Text("No issues found"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: issues.length,
            itemBuilder: (_, index) {
              final issue = issues[index];
              return GestureDetector(
                onLongPress: isAdmin ? () => _deleteIssue(issue.id) : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        elevation: 4,
                        child: issue.image != null && issue.image!.isNotEmpty
                            ? Image.network(
                                issue.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              )
                            : const Icon(Icons.broken_image),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      issue.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
