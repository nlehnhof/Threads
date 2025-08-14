import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raw_threads/classes/main_classes/issues.dart';
import 'dart:async';
import 'package:raw_threads/providers/issues_provider.dart';
import 'package:raw_threads/account/app_state.dart';
import 'package:provider/provider.dart';

class IssueMenuPage extends StatefulWidget {
  const IssueMenuPage({super.key});

  @override
  State<IssueMenuPage> createState() => _IssueMenuPageState();
}

class _IssueMenuPageState extends State<IssueMenuPage> {
  final TextEditingController _titleController = TextEditingController();

  Future<void> _addIssue() async {
    final provider = context.read<IssuesProvider>();
    final picker = ImagePicker();

    // Choose source
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Image Source"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text("Camera")),
          TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text("Gallery")),
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
            onPressed: () =>
                Navigator.pop(context, _titleController.text.trim()),
            child: const Text("OK"),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;

    // Create issue
    final newIssue = Issues(
      id: uuid.v4(),
      title: title,
      image: picked.path,
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
      appBar: AppBar(title: const Text('Issue Menu')),
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: issues.length,
            itemBuilder: (_, index) {
              final issue = issues[index];
              return GestureDetector(
                onLongPress:
                    isAdmin ? () => _deleteIssue(issue.id) : null,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.file(
                          File(issue.image ?? ''),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        color: Colors.black45,
                        child: Text(
                          issue.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
