import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

class IssueMenuPage extends StatefulWidget {
  final String role;
  const IssueMenuPage({super.key, required this.role});

  @override
  State<IssueMenuPage> createState() => _IssueMenuPageState();
}

class _IssueMenuPageState extends State<IssueMenuPage> {
  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _issuesSubscription;

  List<Map<String, dynamic>> issues = [];
  final TextEditingController _titleController = TextEditingController();

  String? adminId;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initUserAndLoadIssues();
  }

  Future<void> _initUserAndLoadIssues() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Determine adminId: if admin, adminId = own uid, else get linked admin id
    if (widget.role == 'admin') {
      adminId = user.uid;
      isAdmin = true;
    } else {
      final snapshot = await _dbRef.child('users').child(user.uid).child('adminId').get();
      adminId = snapshot.exists ? snapshot.value as String : null;
      isAdmin = false;
    }

    if (adminId != null) {
      _listenToIssues();
    }
  }

  void _listenToIssues() {
  final issuesRef = _dbRef.child('admins').child(adminId!).child('issues');
  _issuesSubscription = issuesRef.onValue.listen((event) {
    if (event.snapshot.exists) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        issues = data.entries.map((entry) {
          final map = Map<String, dynamic>.from(entry.value);
          map['id'] = entry.key;
          return map;
        }).toList();
      });
    } else {
      setState(() => issues = []);
    }
  });
}

  Future<void> loadIssues() async {
    if (adminId == null) return;

    final snapshot = await _dbRef.child('admins').child(adminId!).child('issues').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        issues = data.entries.map((entry) {
          final map = Map<String, dynamic>.from(entry.value);
          map['id'] = entry.key; // keep firebase key for delete
          return map;
        }).toList();
      });
    } else {
      setState(() => issues = []);
    }
  }

  Future<void> saveIssues() async {
    if (adminId == null) return;

    Map<String, dynamic> dataToSave = {};
    for (var issue in issues) {
      final id = issue['id'] ?? _dbRef.child('admins').child(adminId!).child('issues').push().key;
      dataToSave[id] = {
        'title': issue['title'],
        'imagePath': issue['imagePath'],
      };
      issue['id'] = id; // assign id if not set
    }

    await _dbRef.child('admins').child(adminId!).child('issues').set(dataToSave);
  }

  Future<void> addIssue() async {
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

    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Issue Title"),
        content: TextField(controller: _titleController),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, _titleController.text.trim()), child: const Text("OK")),
        ],
      ),
    );

    if (title != null && title.isNotEmpty) {
      setState(() {
        issues.add({
          'title': title,
          'imagePath': picked.path,
        });
      });
      _titleController.clear();
      await saveIssues();
    }
  }

  Future<void> deleteIssue(int index) async {
    if (adminId == null) return;
    final issue = issues[index];
    if (issue['id'] != null) {
      await _dbRef.child('admins').child(adminId!).child('issues').child(issue['id']).remove();
    }
    setState(() {
      issues.removeAt(index);
    });
  }

  @override
  void dispose() {
    _issuesSubscription?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issue Menu')),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: addIssue,
              child: const Icon(Icons.add),
            )
          : null,
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
            onLongPress: isAdmin ? () => deleteIssue(index) : null,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              elevation: 4,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(
                      File(issue['imagePath']),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    color: Colors.black45,
                    child: Text(
                      issue['title'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
