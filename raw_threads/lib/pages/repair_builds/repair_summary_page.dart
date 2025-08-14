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
      backgroundColor: myColors.primary,
      appBar: AppBar(
        title: Text('${widget.repair.name} - $title Repair'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RepairPage(role: widget.role)),
                );
            },
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${widget.repair.name}'),
                  Text('Team: ${widget.repair.team}'),
                  Text('Email: ${widget.repair.email}'),
                  Text('Costume #: ${widget.repair.number}'),
                  Text('Comments: ${widget.repair.comments}'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: (widget.repair.issues)
                        .map((e) => Chip(label: Text(e.title)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_thumbnailFile != null)
                    Image.file(_thumbnailFile!, height: 200)
                  else if (widget.repair.photoPath != null && widget.repair.photoPath!.isNotEmpty)
                    Image.file(File(widget.repair.photoPath!), height: 200),
                  const SizedBox(height: 24),
                  if (isAdmin && !widget.repair.completed)
                    Center(
                      child: ElevatedButton(
                        onPressed: _markRepairComplete,
                        child: const Text('Mark Repair Complete'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
