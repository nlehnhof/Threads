import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/services/dance_inventory_service.dart';
import 'package:raw_threads/pages/costume_builds/add_edit_costume_dialog.dart';

class CostumePage extends StatefulWidget {
  final String role;
  final Dances dance;
  final String gender;

  const CostumePage({super.key, required this.role, required this.dance, required this.gender});

  @override
  State<CostumePage> createState() => _CostumePageState();
}

class _CostumePageState extends State<CostumePage> {
  bool get isAdmin => widget.role == 'admin';
  List<CostumePiece> get costumeList => widget.gender == 'Men'
    ? widget.dance.costumesMen
    : widget.dance.costumesWomen;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _addOrEditCostume({CostumePiece? existing, int? index}) async {
    final result = await showDialog<CostumePiece>(
      context: context,
      builder: (_) => AddEditCostumeDialog(
        existing: existing,
        allowDelete: existing != null,
        role: widget.role,
      ),
    );

    if (result == null && index != null) {
      // Delete
      setState(() {
        if (widget.gender == 'Men') {
          widget.dance.costumesMen = List.from(widget.dance.costumesMen)..removeAt(index);
        } else {
          widget.dance.costumesWomen = List.from(widget.dance.costumesWomen)..removeAt(index);
        }
      });
    } else if (result != null) {
      setState(() {
        if (index != null) {
          if (widget.gender == 'Men') {
            final newList = List<CostumePiece>.from(widget.dance.costumesMen);
            newList[index] = result;
            widget.dance.costumesMen = newList;
          } else {
            final newList = List<CostumePiece>.from(widget.dance.costumesWomen);
            newList[index] = result;
            widget.dance.costumesWomen = newList;
          }
        } else {
          if (widget.gender == 'Men') {
            widget.dance.costumesMen = List.from(widget.dance.costumesMen)..add(result);
          } else {
            widget.dance.costumesWomen = List.from(widget.dance.costumesWomen)..add(result);
          }
        }
      });
    }

    // Save the updated dance object
    await DanceInventoryService.instance.update(widget.dance);
    }


  Future<void> _viewCostume(CostumePiece piece) async {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(piece.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (piece.image != null)
            Image.file(piece.image!, height: 150)
          else
            const Icon(Icons.image, size: 50),
          const SizedBox(height: 10),
          Text("Care: ${piece.care ?? 'N/A'}"),
          Text("Clean Up: ${piece.cleanUp ?? 'N/A'}"),
          const SizedBox(height: 10),
          Text("Turn In: ${piece.turnIn ?? 'N/A'}"),
          const SizedBox(height: 10),
          Text("Available: ${piece.available}"),
          Text("Total: ${piece.total}"),

        ],
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
              child: piece.image != null
                  ? Image.file(
                      piece.image!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholderImage(),
                    )
                  : _placeholderImage(),
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
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: List.generate(
            costumeList.length,
            (index) => _buildCostumeCard(costumeList[index], index),
          ),
        ),
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: () => _addOrEditCostume(),
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
