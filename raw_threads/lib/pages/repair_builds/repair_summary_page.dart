import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/providers/costume_provider.dart';
import 'package:raw_threads/providers/repair_provider.dart';
import 'package:raw_threads/classes/main_classes/repairs.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/pages/real_pages/repair_page.dart';

class RepairSummaryPage extends StatefulWidget {
  final Repairs repair;
  final String role;

  const RepairSummaryPage({
    super.key,
    required this.repair,
    required this.role,
  });

  @override
  State<RepairSummaryPage> createState() => _RepairSummaryPageState();
}

class _RepairSummaryPageState extends State<RepairSummaryPage> {
  File? _thumbnailFile;
  bool _loading = true;

  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    final photoPath = widget.repair.photoPath;
    if (photoPath != null && photoPath.isNotEmpty) {
      final file = File(photoPath);
      final thumb = await _compressImage(file);
      if (mounted && thumb != null) {
        setState(() {
          _thumbnailFile = thumb;
        });
      }
    }
    setState(() => _loading = false);
  }

  Future<File?> _compressImage(File file) async {
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

  Future<void> _markRepairComplete() async {
    if (!isAdmin) return;
    final provider = context.read<RepairProvider>();
    final completedRepair = widget.repair.copyWith(completed: true);
    await provider.update(completedRepair);
    if (mounted) Navigator.pop(context); // Go back after marking complete
  }

  @override
  Widget build(BuildContext context) {
    final costume = context.read<CostumesProvider>().getCostumeById(widget.repair.costumeId);
    final title = costume.title;

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        backgroundColor: myColors.secondary,
        elevation: 0,
        title: Text(
          '${widget.repair.name} - $title Repair',
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vogun', fontSize: 24),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RepairPage(role: widget.role)),
              );
            },
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Repair Details",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const Divider(),
                          _buildDetailRow("Name", widget.repair.name),
                          const SizedBox(height: 4),
                          _buildDetailRow("Team", widget.repair.team),
                          const SizedBox(height: 4),
                          _buildDetailRow("Email", widget.repair.email),
                          const SizedBox(height: 4),
                          _buildDetailRow("Costume #", widget.repair.number),
                          const SizedBox(height: 4),
                          _buildDetailRow("Comments", widget.repair.comments),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Issues summary card
                  if (widget.repair.issues.isNotEmpty)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Selected Issues",
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widget.repair.issues.map((e) {
                                return ListTile(
                                  leading: const Icon(Icons.check,
                                      color: Colors.grey),
                                  title: Text(e.title),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Photo card
                  if (_thumbnailFile != null ||
                      (widget.repair.photoPath != null &&
                          widget.repair.photoPath!.isNotEmpty))
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          if (_thumbnailFile != null)
                            Image.file(_thumbnailFile!, height: 220, fit: BoxFit.cover)
                          else
                            Image.file(File(widget.repair.photoPath!),
                                height: 220, fit: BoxFit.cover),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Admin complete button
                  if (isAdmin && !widget.repair.completed)
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                        ),
                        onPressed: _markRepairComplete,
                        child: const Text(
                          'Mark Repair Complete',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Expanded(child: Text(value?.isNotEmpty == true ? value! : "Not Given", style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }
}