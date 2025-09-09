import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import 'package:raw_threads/classes/main_classes/shows.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/pages/show_builds/dance_selection_page.dart';
import 'package:raw_threads/pages/show_builds/dance_with_status.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';

class EditShowPage extends StatefulWidget {
  final Shows show;
  final void Function(Shows updatedShow) onSave;

  const EditShowPage({required this.show, required this.onSave, super.key});

  @override
  State<EditShowPage> createState() => _EditShowPageState();
}

class _EditShowPageState extends State<EditShowPage> {
  late List<String> _selectedDanceIds;
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _datesController;
  late TextEditingController _techController;
  late TextEditingController _dressController;

  final Map<String, DanceStatus> danceStatusMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDanceIds = List<String>.from(widget.show.danceIds);
    _titleController = TextEditingController(text: widget.show.title);
    _locationController = TextEditingController(text: widget.show.location);
    _datesController = TextEditingController(text: widget.show.dates);
    _techController = TextEditingController(text: widget.show.tech);
    _dressController = TextEditingController(text: widget.show.dress);

    _loadDanceStatuses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _datesController.dispose();
    _techController.dispose();
    _dressController.dispose();
    super.dispose();
  }

  Future<void> _selectDances() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => DanceSelectionPage(
          adminId: widget.show.adminId,
          initiallySelectedIds: _selectedDanceIds,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        // Add new dances
        final danceProvider = context.read<DanceInventoryProvider>();
        for (var id in result) {
          if (!danceStatusMap.containsKey(id)) {
            final dance = danceProvider.getDanceById(id);
            if (dance != null) {
              danceStatusMap[id] = DanceStatus(dance: dance);
            }
          }
        }
        // Remove deselected dances
        danceStatusMap.removeWhere((id, _) => !result.contains(id));
        _selectedDanceIds = result;
      });
    }
  }

  Future<void> _loadDanceStatuses() async {
    final db = FirebaseDatabase.instance.ref();
    final ref = db.child('admins/${widget.show.adminId}/shows/${widget.show.id}/danceStatuses');
    final snapshot = await ref.get();

    final loadedStatuses = <String, DanceStatus>{};
    final danceProvider = context.read<DanceInventoryProvider>();

    if (snapshot.exists) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      data.forEach((danceId, value) {
        final dance = danceProvider.getDanceById(danceId.toString());
        if (dance != null) {
          loadedStatuses[dance.id] = DanceStatus.fromJson(
            Map<dynamic, dynamic>.from(value),
            dance,
          );
        }
      });
    }

    // Ensure all selected dances exist
    for (var id in _selectedDanceIds) {
      if (!loadedStatuses.containsKey(id)) {
        final dance = danceProvider.getDanceById(id);
        if (dance != null) {
          loadedStatuses[id] = DanceStatus(dance: dance);
        }
      }
    }

    setState(() {
      danceStatusMap
        ..clear()
        ..addAll(loadedStatuses);
    });
  }

  Future<void> _saveShow(BuildContext ctx) async {
    final updatedShow = Shows(
      id: widget.show.id,
      title: _titleController.text,
      dates: _datesController.text,
      tech: _techController.text,
      dress: _dressController.text,
      location: _locationController.text,
      category: widget.show.category,
      danceIds: _selectedDanceIds,
      adminId: widget.show.adminId,
    );

    final db = FirebaseDatabase.instance.ref();
    final showRef = db.child('admins/${updatedShow.adminId}/shows/${updatedShow.id}');

    try {
      // Save main show info
      await showRef.update(updatedShow.toJson());

      // Save all dance statuses in bulk
      final updates = <String, dynamic>{};
      danceStatusMap.forEach((id, ds) {
        updates[id] = {'status': ds.status};
      });
      await showRef.child('danceStatuses').update(updates);

      widget.onSave(updatedShow);
      Navigator.of(ctx).pop(updatedShow);
    } catch (e) {
      debugPrint('Failed to save show: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save show')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDances = _selectedDanceIds
        .map((id) => danceStatusMap[id]?.dance)
        .whereType<Dances>()
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Show')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location')),
            TextField(controller: _datesController, decoration: const InputDecoration(labelText: 'Dates')),
            TextField(controller: _techController, decoration: const InputDecoration(labelText: 'Tech')),
            TextField(controller: _dressController, decoration: const InputDecoration(labelText: 'Dress')),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Selected Dances', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton(
                  onPressed: _selectDances,
                  child: const Text('Select Dances'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: selectedDances.length,
                itemBuilder: (ctx, index) {
                  final dance = selectedDances[index];
                  final danceStatus = danceStatusMap[dance.id]!;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dance.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: danceStatus.status,
                            items: ['Prepped', 'Distributed', 'Not Ready']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => danceStatus.status = val);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              final danceId = dance.id;

                              setState(() {
                                _selectedDanceIds.remove(danceId);
                                danceStatusMap.remove(danceId);
                              });

                              final db = FirebaseDatabase.instance.ref();
                              final showRef = db.child('admins/${widget.show.adminId}/shows/${widget.show.id}');

                              // Remove danceStatus entry
                              await showRef.child('danceStatuses/$danceId').remove();

                              // Remove danceId from the show's danceIds array
                              final snapshot = await showRef.child('danceIds').get();
                              if (snapshot.exists) {
                                final List<dynamic> danceIds = List<dynamic>.from(snapshot.value as List);
                                danceIds.remove(danceId);
                                await showRef.child('danceIds').set(danceIds);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => _saveShow(context),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
