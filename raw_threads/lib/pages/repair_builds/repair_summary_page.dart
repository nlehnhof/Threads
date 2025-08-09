import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class RepairSummaryPage extends StatefulWidget {
  final String repairKey;
  final String role;
  final String costumeTitle;

  const RepairSummaryPage({
    super.key,
    required this.role,
    required this.costumeTitle,
    required this.repairKey,
  });

  @override
  State<RepairSummaryPage> createState() => _RepairSummaryPageState();
}

class _RepairSummaryPageState extends State<RepairSummaryPage> {
  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref();

  Map<String, dynamic>? repairData;
  File? _thumbnailFile;
  String? _adminId;
  bool _loading = true;

  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    _loadAdminIdAndRepair();
  }

  Future<void> _loadAdminIdAndRepair() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (isAdmin) {
      _adminId = user.uid;
    } else {
      final snapshot = await _dbRef.child('users').child(user.uid).child('adminId').get();
      if (snapshot.exists) {
        _adminId = snapshot.value as String?;
      }
    }

    if (_adminId != null) {
      await _loadRepairData();
    }
  }

  Future<void> _loadRepairData() async {
    if (_adminId == null) return;

    final snapshot = await _dbRef.child('admins').child(_adminId!).child('repairs').child(widget.repairKey).get();

    if (snapshot.exists) {
      setState(() {
        repairData = Map<String, dynamic>.from(snapshot.value as Map);
        _loading = false;
      });

      // If there's a photo path, generate a compressed thumbnail
      final photoPath = repairData?['photoPath'] as String?;
      if (photoPath != null && photoPath.isNotEmpty) {
        final originalFile = File(photoPath);
        final thumb = await _compressImage(originalFile);
        if (mounted && thumb != null) {
          setState(() {
            _thumbnailFile = thumb;
          });
        }
      }
    } else {
      setState(() {
        repairData = null;
        _loading = false;
      });
    }
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

    if (compressedFile == null) return null;

    return File(compressedFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.costumeTitle} Repair'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : repairData == null
              ? const Center(child: Text('No repair data found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${repairData!['name'] ?? ''}'),
                      Text('Team: ${repairData!['team'] ?? ''}'),
                      Text('Email: ${repairData!['email'] ?? ''}'),
                      Text('Costume #: ${repairData!['costumeNumbers'] ?? ''}'),
                      Text('Comments: ${repairData!['comments'] ?? ''}'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: (repairData!['selectedIssues'] as List<dynamic>? ?? [])
                            .map((e) => Chip(label: Text(e['title'] ?? '')))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      if (_thumbnailFile != null)
                        Image.file(_thumbnailFile!, height: 200)
                      else if (repairData!['photoPath'] != null && (repairData!['photoPath'] as String).isNotEmpty)
                        Image.file(File(repairData!['photoPath']), height: 200),
                    ],
                  ),
                ),
    );
  }
}
