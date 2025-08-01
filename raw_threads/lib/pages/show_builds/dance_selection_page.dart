import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';

class DanceSelectionPage extends StatefulWidget {
  final List<Dances> allDances;
  final List<String> initiallySelectedIds;

  const DanceSelectionPage({
    super.key,
    required this.allDances,
    required this.initiallySelectedIds,
  });

  @override
  State<DanceSelectionPage> createState() => _DanceSelectionPageState();
}

class _DanceSelectionPageState extends State<DanceSelectionPage> {
  late Set<String> selectedIds;

  @override
  void initState() {
    super.initState();
    selectedIds = widget.initiallySelectedIds.toSet();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColors.secondary,
        title: const Text('Select Dances'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(selectedIds.toList()),
            child: const Text('Done', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.allDances.length,
        itemBuilder: (ctx, index) {
          final dance = widget.allDances[index];
          final isSelected = selectedIds.contains(dance.id);
          return ListTile(
            title: Text(dance.title),
            trailing: isSelected
                ? const Icon(Icons.check_box, color: Colors.green)
                : const Icon(Icons.check_box_outline_blank),
            onTap: () => _toggleSelection(dance.id),
          );
        },
      ),
    );
  }
}
