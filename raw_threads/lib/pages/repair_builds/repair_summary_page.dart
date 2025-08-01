import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raw_threads/pages/real_pages/repair_page.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class RepairSummaryPage extends StatefulWidget {
  final String danceTitle;
  final String costumeTitle;

  const RepairSummaryPage({
    super.key,
    required this.danceTitle,
    required this.costumeTitle,
  });

  @override
  State<RepairSummaryPage> createState() => _RepairSummaryPageState();
}

class _RepairSummaryPageState extends State<RepairSummaryPage> {
  late Future<Map<String, dynamic>> _repairDataFuture;
  File? _thumbnailFile;

  @override
  void initState() {
    super.initState();
    _repairDataFuture = loadRepairData();
  }

  Future<Map<String, dynamic>> loadRepairData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('last_repair_${widget.danceTitle}_${widget.costumeTitle}');
    final data = jsonDecode(raw!);

    if (data['photoPath'] != null && data['photoPath'].isNotEmpty) {
      final originalFile = File(data['photoPath']);
      final thumb = await compressImage(originalFile);

      if (mounted) {  // <-- check if widget still mounted
        setState(() {
          _thumbnailFile = thumb;
        });
      }
    }

    return data;
  }

  Future<File?> compressImage(File file) async {
    final targetPath = file.path.replaceFirst('.jpg', '_thumb.jpg');
    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 50,
      minWidth: 200,
      minHeight: 200,
    );
    
    if (result == null) return null;
    return File(result.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.costumeTitle} Repair'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => RepairPage()),
                (route) => false,
              );
            },
            child: const Text('Done', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _repairDataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${data['name']}'),
                Text('Team: ${data['team']}'),
                Text('Email: ${data['email']}'),
                Text('Costume #: ${data['costumeNumbers']}'),
                Text('Comments: ${data['comments']}'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: (data['selectedIssues'] as List<dynamic>)
                      .map((e) => Chip(label: Text(e)))
                      .toList(),
                ),
                const SizedBox(height: 16),
                if (_thumbnailFile != null)
                  Image.file(_thumbnailFile!, height: 200)
                else if (data['photoPath'] != null && data['photoPath'].isNotEmpty)
                  Image.file(File(data['photoPath']), height: 200),
              ],
            ),
          );
        },
      ),
    );
  }
}
