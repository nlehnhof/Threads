import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raw_threads/classes/main_classes/issues.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/classes/main_classes/repairs.dart';
import 'package:raw_threads/providers/repair_provider.dart';
import 'package:raw_threads/providers/issues_provider.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'repair_summary_page.dart';
import 'package:uuid/uuid.dart';

final uuid = Uuid();

class RepairDetailsPage extends StatefulWidget {
  final Dances dance;
  final CostumePiece costume;
  final String role;
  final String gender;
  final String? repairKey;
  final String costumeTitle;

  const RepairDetailsPage(
    this.role, {
    super.key,
    required this.dance,
    required this.costume,
    required this.gender,
    required this.costumeTitle,
    this.repairKey,
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

  bool get isAdmin => widget.role == 'admin';

  Repairs? existingRepair;

  @override
  void initState() {
    super.initState();
    _loadRepair();
    _listenIssues();
  }

  void _loadRepair() {
    final provider = context.read<RepairProvider>();
    if (widget.repairKey != null) {
      final repair = provider.getRepairById(widget.repairKey!);
      if (repair != null) {
        existingRepair = repair;
        nameController.text = repair.name;
        emailController.text = repair.email;
        costumeNumberController.text = repair.number;
        commentController.text = repair.comments ?? '';
        issueOptions = repair.issues.map((i) {
          return {
            'title': i.title,
            'image': i.image,
            'selected': true,
          };
        }).toList();
      }
    }
  }

  void _listenIssues() {
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    issuesProvider.addListener(() {
      final updatedIssues = issuesProvider.allIssues.map((i) {
        final existing = issueOptions.firstWhere(
          (opt) => opt['title'] == i.title,
          orElse: () => {'title': i.title, 'image': i.image, 'selected': false},
        );
        return {
          'title': i.title,
          'image': i.image,
          'selected': existing['selected'] ?? false,
        };
      }).toList();

      setState(() {
        issueOptions = updatedIssues;
      });
    });
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
      setState(() => photo = File(file.path));
    }
  }

  Widget buildIssueCard(Map<String, dynamic> issue, int index) {
    final selected = issue['selected'] == true;
    final imageSource = issue['image'];
    Widget imageWidget;

    if (imageSource != null && imageSource.startsWith('http')) {
      imageWidget = Image.network(imageSource, width: 100, height: 100, fit: BoxFit.cover);
    } else if (imageSource != null && imageSource.isNotEmpty) {
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
          Opacity(opacity: selected ? 0.5 : 1.0, child: imageWidget),
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

  Future<void> saveRepairData() async {
    final provider = context.read<RepairProvider>();

    final issues = issueOptions
        .where((i) => i['selected'] == true)
        .map((i) => Issues(
              id: i['id'] ?? uuid.v4(),
              title: i['title'],
              image: i['image'],
            ))
        .toList();

    final repairId = existingRepair?.id ?? uuid.v4();

    final repair = Repairs(
      id: repairId,
      danceId: widget.dance.id,
      gender: widget.gender,
      team: teamController.text,
      costumeTitle: widget.costume.title,
      costumeId: widget.costume.id,
      name: nameController.text,
      email: emailController.text,
      number: costumeNumberController.text,
      issues: issues,
      comments: commentController.text,
      completed: false,
    );

    // Add/update in provider (and Firebase)
    if (existingRepair != null) {
      await provider.update(repair);
    } else {
      await provider.add(repair);
    }

    // Navigate to summary page
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RepairSummaryPage(
            repair: repair,
            role: widget.role,
          ),
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none, // removes underline
          ),
        ),
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
    final issuesProvider = context.watch<IssuesProvider>();
    final allIssues = issuesProvider.allIssues;

    // Merge existing selected issues with provider issues
    issueOptions = allIssues.map((issue) {
      final existing = issueOptions.firstWhere(
        (opt) => opt['title'] == issue.title,
        orElse: () => {
          'title': issue.title,
          'image': issue.image,
          'selected': false
        },
      );
      return {
        'title': issue.title,
        'image': issue.image,
        'selected': existing['selected'] ?? false,
      };
    }).toList();

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        backgroundColor: myColors.secondary,
        elevation: 0,
        title: Text(
          '${widget.dance.title} - ${widget.costume.title}',
          style: const TextStyle(color: Colors.black, fontFamily: 'Vogun', fontSize: 32, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What needs fixing?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Vogun',
              ),
            ),
            const SizedBox(height: 12),

            // Issues grid
            allIssues.isEmpty
                ? const Text("No issues found. Add some to the Issue Menu.")
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: issueOptions.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150, // square cards
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8, // room for title
                    ),
                    itemBuilder: (_, index) {
                      final issue = issueOptions[index];
                      final selected = issue['selected'] == true;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            issueOptions[index]['selected'] = !selected;
                          });
                        },
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 1, // square image
                              child: Card(
                                elevation: selected ? 6 : 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    issue['image'] != null &&
                                            issue['image'].toString().isNotEmpty
                                        ? Image.file(
                                            File(issue['image']),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.broken_image),
                                          )
                                        : const Icon(Icons.broken_image),
                                    if (selected)
                                      Container(
                                        color: Colors.black45,
                                        child: const Icon(Icons.check,
                                            color: Colors.white, size: 40),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              issue['title'],
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
                  ),

            const SizedBox(height: 24),
            // Form fields
            _buildTextField(controller: nameController, label: 'Name'),
            _buildTextField(controller: teamController, label: 'Team'),
            _buildTextField(controller: emailController, label: 'Email'),
            _buildTextField(controller: costumeNumberController, label: 'Costume Number(s)'),
            _buildTextField(controller: commentController, label: 'Comments'),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: pickImage,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Center(
                    child: photo != null
                        ? Image.file(photo!,
                            fit: BoxFit.cover, width: double.infinity)
                        : const Text('Tap to take a picture'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty ||
                      teamController.text.trim().isEmpty ||
                      emailController.text.trim().isEmpty ||
                      costumeNumberController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill out all required fields (Name, Team, Email, Costume #)."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  saveRepairData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: myColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit Repair',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}