import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/services/dance_inventory_service.dart';
import 'package:raw_threads/pages/costume_builds/add_edit_costume_dialog.dart';

class CostumePage extends StatefulWidget {
  final Dances dance;
  final String gender;

  const CostumePage({super.key, required this.dance, required this.gender});

  @override
  State<CostumePage> createState() => _CostumePageState();
}

class _CostumePageState extends State<CostumePage> {
  late Dances dance;
  late List<CostumePiece> costumeList;

  @override
  void initState() {
    super.initState();
    dance = widget.dance;
    costumeList = widget.gender == 'Men' ? dance.costumesMen : dance.costumesWomen;
  }

  Future<void> _addOrEditCostume({CostumePiece? existing, int? index}) async {
    final result = await showDialog<CostumePiece>(
      context: context,
      builder: (_) => AddEditCostumeDialog(
        existing: existing,
        allowDelete: existing != null,
      ),
    );

    if (result == null && index != null) {
      // Delete
      setState(() {
        costumeList.removeAt(index);
      });
    } else if (result != null) {
      setState(() {
        if (index != null) {
          costumeList[index] = result;
        } else {
          costumeList.add(result);
        }
      });
    }

    // Update dance object and save
    if (widget.gender == 'Men') {
      dance.costumesMen = costumeList;
    } else {
      dance.costumesWomen = costumeList;
    }

    await DanceInventoryService.instance.update(dance);
  }

  Widget _buildCostumeCard(CostumePiece piece, int index) {
    return GestureDetector(
      onTap: () => _addOrEditCostume(existing: piece, index: index),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditCostume(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
