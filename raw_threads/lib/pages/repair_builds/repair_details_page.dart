import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'repair_summary_page.dart';

class RepairDetailsPage extends StatefulWidget {
  final Dances dance;
  final CostumePiece costume;

  const RepairDetailsPage({
    super.key,
    required this.dance,
    required this.costume,
  });

  @override
  State<RepairDetailsPage> createState() => _RepairDetailsPageState();
}

class _RepairDetailsPageState extends State<RepairDetailsPage> {
  List<Map<String, dynamic>> issueOptions = [];
  File? photo;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController teamController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController costumeNumberController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadGlobalIssues();
  }

  Future<void> loadGlobalIssues() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('global_repair_issues');
    if (stored != null) {
      final decoded = jsonDecode(stored) as List;
      setState(() {
        issueOptions = decoded
            .map((e) => {
                  'title': e['title'],
                  'image': File(e['imagePath']),
                  'selected': false,
                })
            .toList();
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

    if (compressedFile == null) return null;
    return File(compressedFile.path);
  }

  Future<void> saveRepairData() async {
    final prefs = await SharedPreferences.getInstance();

    String? thumbPath;

    if (photo != null) {
      final thumbFile = await compressImage(photo!);
      if (thumbFile != null) {
        thumbPath = thumbFile.path;
      }
    }

    final selectedIssues = issueOptions
        .where((issue) => issue['selected'] == true)
        .map((issue) => {
              'title': issue['title'],
              'imagePath': issue['image'].path,
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
      'thumbnailPath': thumbPath ?? '',
    };

    await prefs.setString(
      'last_repair_${widget.dance.id}_${widget.costume.title}',
      jsonEncode(repairData),
    );
  }

  Widget buildIssueCard(Map<String, dynamic> issue, int index) {
    final selected = issue['selected'] == true;
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
            child: Image.file(
              issue['image'],
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
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
                ? const Text("No issues found. Add some from the Issue Menu.")
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
