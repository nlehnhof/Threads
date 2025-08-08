import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/pages/costume_builds/add_edit_costume_dialog.dart';
import 'package:raw_threads/providers/assignments_provider.dart';
import 'package:raw_threads/providers/costume_provider.dart';
import 'package:raw_threads/pages/assignment_builds/assign_page.dart';

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
  String get genderKey => widget.gender == 'Men' ? 'Men' : 'Women';
  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    _loadCostumes;
  }

  void _loadCostumes(CostumePiece? existing) async {
    final provider = context.read<CostumesProvider>();
    if (existing != null) {
      await provider.loadCostume(existing);
    }
  }

  Future<void> _addOrEditCostume({CostumePiece? existing, int? index}) async {
    final provider = context.read<CostumesProvider>();

    final result = await showDialog<CostumePiece?>(
      context: context,
      builder: (_) => AddEditCostumeDialog(
        existing: existing,
        allowDelete: existing != null,
        onSave: (_) {},
        role: widget.role,
      ),
    );

    if (result == null && existing != null && index != null) {
      await provider.deleteCostume(widget.dance.id);
    } else if (result != null) {
      if (existing != null) {
        await provider.updateCostume(existing);
      } else {
        await provider.addCostume(existing!);
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
        imageWidget = Image.file(file, fit: BoxFit.cover, width: double.infinity, height: 150);
      } else {
        imageWidget = _placeholderImage();
      }
    } else {
      imageWidget = _placeholderImage();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => AssignmentsProvider(
                danceId: widget.dance.id, 
                gender: widget.gender, 
                costumeId: piece.id,
              ),
              child: AssignPage(
                costume: piece, 
                role: widget.role,
              ), 
            ), 
          ),
        );
      },
      onLongPress: () {
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
            child: SizedBox(height: 150, width: double.infinity, child: imageWidget),
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
    final provider = context.watch<CostumesProvider>();
    final costumes = provider.costumes;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gender} - ${widget.dance.title}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(4),
        child: costumes.isEmpty
            ? const Center(child: Text("No costumes found."))
            : GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: List.generate(
                  costumes.length,
                  (index) => _buildCostumeCard(costumes[index], index),
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
