import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/pages/costume_builds/add_edit_costume_dialog.dart';
import 'package:raw_threads/services/costume_inventory_service.dart';

class CostumePage extends StatefulWidget {
  final String role;
  final Dances dance;
  final String gender;

  const CostumePage({
    super.key,
    required this.role,
    required this.dance,
    required this.gender,
  });

  @override
  State<CostumePage> createState() => _CostumePageState();
}

class _CostumePageState extends State<CostumePage> {
  bool get isAdmin => widget.role == 'admin';

  List<CostumePiece> costumeList = [];
  String? danceId;
  String get genderKey => widget.gender == 'Men' ? 'Men' : 'Women';

  StreamSubscription? _listenerSub;

  @override
  void initState() {
    super.initState();
    _initListeners();
  }

  Future<void> _initListeners() async {
    danceId = widget.dance.id;

    if (danceId == null) return;

    // Load cached costumes first
    await CostumeInventoryService.instance.load(danceId!, genderKey);
    setState(() {
      costumeList = CostumeInventoryService.instance.costumes;
    });

    // Listen for live updates from Firebase and update UI accordingly
    _listenerSub = await CostumeInventoryService.instance.listenToCostumes(
      danceId: danceId!,
      gender: genderKey,
      onUpdate: (updatedList) {
        if (!mounted) return;
        setState(() {
          costumeList = updatedList;
        });
      },
    );
  }

  @override
  void dispose() {
    _listenerSub?.cancel();
    super.dispose();
  }

  Future<void> _addOrEditCostume({CostumePiece? existing, int? index}) async {
    final result = await showDialog<CostumePiece?>(
      context: context,
      builder: (_) => AddEditCostumeDialog(
        existing: existing,
        allowDelete: existing != null,
        onSave: (_) {},
        role: widget.role,
      ),
    );

    if (result == null && index != null) {
      // Delete costume
      if (danceId != null) {
        await CostumeInventoryService.instance.delete(danceId!, genderKey, costumeList[index].id);
      }
    } else if (result != null) {
      if (danceId == null) return;

      if (index != null) {
        // Update existing costume
        await CostumeInventoryService.instance.update(danceId!, genderKey, result);
      } else {
        // Add new costume
        await CostumeInventoryService.instance.add(danceId!, genderKey, result);
      }
    }
  }

  Future<void> _viewCostume(CostumePiece piece) async {
    Widget imageWidget;
    if (piece.imagePath != null && piece.imagePath!.isNotEmpty) {
      final file = File(piece.imagePath!);
      if (file.existsSync()) {
        imageWidget = Image.file(file, height: 150, fit: BoxFit.cover);
      } else {
        imageWidget = _placeholderImage();
      }
    } else {
      imageWidget = _placeholderImage();
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(piece.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              imageWidget,
              const SizedBox(height: 10),
              Text("Care: ${piece.care}"),
              const SizedBox(height: 10),
              Text("Turn In: ${piece.turnIn}"),
              const SizedBox(height: 10),
              Text("Available: ${piece.available}"),
              Text("Total: ${piece.total}"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildCostumeCard(CostumePiece piece, int index) {
    Widget imageWidget;
    if (piece.imagePath != null && piece.imagePath!.isNotEmpty) {
      final file = File(piece.imagePath!);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 150,
        );
      } else {
        imageWidget = _placeholderImage();
      }
    } else {
      imageWidget = _placeholderImage();
    }

    return GestureDetector(
      onTap: () {
        if (isAdmin) {
          _addOrEditCostume(existing: piece, index: index);
        } else {
          _viewCostume(piece);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: imageWidget,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    piece.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ),
                Text(
                  "${piece.available}/${piece.total}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gender} - ${widget.dance.title}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(4),
        child: costumeList.isEmpty
            ? const Center(child: Text("No costumes found."))
            : GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: List.generate(
                  costumeList.length,
                  (index) => _buildCostumeCard(costumeList[index], index),
                ),
              ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _addOrEditCostume(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
