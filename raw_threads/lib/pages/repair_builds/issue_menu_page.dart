import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IssueMenuPage extends StatefulWidget {
  final String role;
  const IssueMenuPage({super.key, required this.role});

  @override
  State<IssueMenuPage> createState() => _IssueMenuPageState();
}

class _IssueMenuPageState extends State<IssueMenuPage> {
  List<Map<String, dynamic>> issues = [];
  final TextEditingController _titleController = TextEditingController();
  bool isAdmin = true;

  @override
  void initState() {
    super.initState();
    loadIssues();
  }

  Future<void> loadIssues() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('global_repair_issues');
    if (stored != null) {
      final decoded = jsonDecode(stored) as List;
      setState(() {
        issues = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> saveIssues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_repair_issues', jsonEncode(issues));
  }

  Future<void> addIssue() async {
    final picker = ImagePicker();
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

    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Issue Title"),
        content: TextField(controller: _titleController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _titleController.text),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (title != null && title.trim().isNotEmpty) {
      setState(() {
        issues.add({
          'title': title.trim(),
          'imagePath': picked.path,
        });
      });
      _titleController.clear();
      await saveIssues();
    }
  }

  Future<void> deleteIssue(int index) async {
    setState(() {
      issues.removeAt(index);
    });
    await saveIssues();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role == 'admin') {
      isAdmin;
    } else {
      isAdmin = false;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Issue Menu')),
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: addIssue,
        child: const Icon(Icons.add),
      ) : null,
      body: GridView.builder(
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
            onLongPress: () => isAdmin ? deleteIssue(index) : null,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              elevation: 4,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(
                      File(issue['imagePath']),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    color: Colors.black45,
                    child: Text(
                      issue['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
