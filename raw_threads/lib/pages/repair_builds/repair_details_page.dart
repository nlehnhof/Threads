import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'repair_summary_page.dart';

class RepairDetailsPage extends StatefulWidget {
  final Dances dance;
  final CostumePiece costume;
  final String role;

  const RepairDetailsPage(
    this.role, {
    super.key,
    required this.dance,
    required this.costume,
  });

  @override
  State<RepairDetailsPage> createState() => _RepairDetailsPageState();
}

class _RepairDetailsPageState extends State<RepairDetailsPage> {
  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref();

  String? adminId;

  List<Map<String, dynamic>> issueOptions = [];
  File? photo;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController teamController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController costumeNumberController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    _initUserAndLoadData();
  }

  Future<void> _initUserAndLoadData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (isAdmin) {
      adminId = user.uid;
    } else {
      final adminSnap = await _dbRef.child('users').child(user.uid).child('adminId').get();
      adminId = adminSnap.exists ? adminSnap.value as String : null;
    }

    if (adminId != null) {
      await loadGlobalIssues();
      await loadRepairData();
    }
  }

  Future<void> loadGlobalIssues() async {
    if (adminId == null) return;
    final snapshot = await _dbRef.child('admins').child(adminId!).child('issues').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        issueOptions = data.entries.map((entry) {
          final map = Map<String, dynamic>.from(entry.value);
          map['selected'] = false;
          map['image'] = map['imagePath'];
          return map;
        }).toList();
      });
    } else {
      setState(() => issueOptions = []);
    }
  }

  Future<void> loadRepairData() async {
    if (adminId == null) return;
    final key = '${widget.dance.id}_${widget.costume.title}';
    final snapshot = await _dbRef.child('admins').child(adminId!).child('repairs').child(key).get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
        nameController.text = data['name'] ?? '';
        teamController.text = data['team'] ?? '';
        emailController.text = data['email'] ?? '';
        costumeNumberController.text = data['costumeNumbers'] ?? '';
        commentController.text = data['comments'] ?? '';
        photo = (data['photoPath'] != null && (data['photoPath'] as String).isNotEmpty)
            ? File(data['photoPath'])
            : null;

        // Set selected issues based on saved repair data
        List<dynamic> savedIssues = data['selectedIssues'] ?? [];
        for (var issue in issueOptions) {
          issue['selected'] = savedIssues.any((saved) => saved['title'] == issue['title']);
        }
      });
    }
  }

  Future<void> pickImage() async {
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

    final file = await picker.pickImage(source: source);
    if (file != null) {
      setState(() {
        photo = File(file.path);
      });
    }
  }

  Future<File?> compressImage(File file) async {
    final targetPath = file.path.replaceFirst('.jpg', '_thumb.jpg');
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 50,
      minWidth: 200,
      minHeight: 200,
    );

    return compressedFile != null ? File(compressedFile.path) : null;
  }

  Future<void> saveRepairData() async {
    if (adminId == null) return;

    final selectedIssues = issueOptions
        .where((issue) => issue['selected'] == true)
        .map((issue) => {
              'title': issue['title'],
              'imagePath': issue['image'],
            })
        .toList();

    final repairData = {
      'danceId': widget.dance.id,
      'danceTitle': widget.dance.title,
      'costumeTitle': widget.costume.title,
      'selectedIssues': selectedIssues,
      'name': nameController.text,
      'team': teamController.text,
      'email': emailController.text,
      'costumeNumbers': costumeNumberController.text,
      'comments': commentController.text,
      'photoPath': photo?.path ?? '',
      // add 'thumbnailPath' here if you generate and want to save thumbnails
    };

    final key = '${widget.dance.id}_${widget.costume.title}';

    await _dbRef.child('admins').child(adminId!).child('repairs').child(key).set(repairData);
  }

  Widget buildIssueCard(Map<String, dynamic> issue, int index) {
    final selected = issue['selected'] == true;
    final imageSource = issue['image'];
    Widget imageWidget;

    if (imageSource is String && imageSource.startsWith('http')) {
      imageWidget = Image.network(imageSource, width: 100, height: 100, fit: BoxFit.cover);
    } else if (imageSource is String) {
      imageWidget = Image.file(File(imageSource), width: 100, height: 100, fit: BoxFit.cover);
    } else {
      imageWidget = const Icon(Icons.broken_image, size: 100);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          issueOptions[index]['selected'] = !selected;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: selected ? 0.5 : 1.0,
            child: imageWidget,
          ),
          if (selected)
            Container(
              width: 100,
              height: 100,
              color: Colors.black45,
              alignment: Alignment.center,
              child: Text(
                issue['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    teamController.dispose();
    emailController.dispose();
    costumeNumberController.dispose();
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.dance.title} - ${widget.costume.title}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Repair Issues:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            issueOptions.isEmpty
                ? const Text("No issues found. Add some to the Issue Menu.")
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(
                      issueOptions.length,
                      (index) => buildIssueCard(issueOptions[index], index),
                    ),
                  ),
            const SizedBox(height: 20),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: teamController, decoration: const InputDecoration(labelText: 'Team')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: costumeNumberController, decoration: const InputDecoration(labelText: 'Costume Number(s)')),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Comments'),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: pickImage,
              child: Card(
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Center(
                    child: photo != null
                        ? Image.file(photo!, fit: BoxFit.cover, width: double.infinity)
                        : const Text('Tap to take a picture'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await saveRepairData();
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RepairSummaryPage(
                          danceTitle: widget.dance.title,
                          costumeTitle: widget.costume.title,
                          role: widget.role,
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Submit Repair'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
