import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:firebase_database/firebase_database.dart';

class DanceSelectionPage extends StatefulWidget {
  final String adminId;
  final List<String> initiallySelectedIds;

  const DanceSelectionPage({
    super.key,
    required this.adminId,
    required this.initiallySelectedIds,
  });

  @override
  State<DanceSelectionPage> createState() => _DanceSelectionPageState();
}

class _DanceSelectionPageState extends State<DanceSelectionPage> {
  late Set<String> selectedIds;
  List<Dances> allDances = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedIds = widget.initiallySelectedIds.toSet();
    fetchDancesFromFirebase();
  }

  Future<void> fetchDancesFromFirebase() async {
    setState(() => isLoading = true);
    try {
      final ref = FirebaseDatabase.instance.ref('dances/${widget.adminId}');
      final snapshot = await ref.get();
      if (snapshot.exists) {
        final Map data = snapshot.value as Map;
        final dances = data.entries.map((entry) {
          return Dances.fromJson({
            ...entry.value,
            'id': entry.key,
          });
        }).toList();

        setState(() => allDances = dances);
      }
    } catch (e) {
      debugPrint('Failed to fetch dances: $e');
    } finally {
      setState(() => isLoading = false);
    }
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: allDances.length,
              itemBuilder: (ctx, index) {
                final dance = allDances[index];
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
