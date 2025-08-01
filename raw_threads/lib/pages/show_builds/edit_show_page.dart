import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/shows.dart';
import 'package:raw_threads/classes/main_classes/dances.dart'; 
import 'package:raw_threads/pages/show_builds/dance_selection_page.dart';
import 'package:raw_threads/services/dance_inventory_service.dart';

class DanceStatusAndTeams {
  String status;
  Set<String> teams;
  DanceStatusAndTeams({required this.status, required this.teams});
}

class EditShowPage extends StatefulWidget {
  final Shows show;
  final void Function(Shows updatedShow) onSave;

  const EditShowPage({required this.show, required this.onSave, super.key});

  @override
  State<EditShowPage> createState() => _EditShowPageState();
}

class _EditShowPageState extends State<EditShowPage> {
  final DanceInventoryService _inventory = DanceInventoryService.instance;

  late List<String> _selectedDanceIds;
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _datesController;
  late TextEditingController _techController;
  late TextEditingController _dressController;

  final Map<String, DanceStatusAndTeams> danceStatusMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDanceIds = List<String>.from(widget.show.danceIds);
    _titleController = TextEditingController(text: widget.show.title);
    _locationController = TextEditingController(text: widget.show.location);
    _datesController = TextEditingController(text: widget.show.dates);
    _techController = TextEditingController(text: widget.show.tech);
    _dressController = TextEditingController(text: widget.show.dress);
    
    for (var id in _selectedDanceIds) {
      danceStatusMap[id] = DanceStatusAndTeams(status: 'Not Ready', teams: {});
    }
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
          allDances: _inventory.dances,
          initiallySelectedIds: _selectedDanceIds,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        for (var id in result) {
          danceStatusMap.putIfAbsent(id, () => DanceStatusAndTeams(status: 'Not Ready', teams: {}));
        }
        danceStatusMap.removeWhere((id, _) => !result.contains(id));
        _selectedDanceIds = result;
      });
    }
  }

  void _saveShow(BuildContext ctx) {
    final updatedShow = Shows(
      id: widget.show.id,
      title: _titleController.text,
      dates: _datesController.text,
      tech: _techController.text,
      dress: _dressController.text,
      location: _locationController.text,
      category: widget.show.category,
      danceIds: _selectedDanceIds,
    );
    widget.onSave(updatedShow);
    Navigator.of(ctx).pop(updatedShow);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDances = _selectedDanceIds
        .map((id) => _inventory.getById(id))
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
                  final statusTeams = danceStatusMap[dance.id]!;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dance.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text("Status: "),
                              DropdownButton<String>(
                                value: statusTeams.status,
                                items: ['Prepped', 'Distributed', 'Not Ready']
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => statusTeams.status = val);
                                  }
                                },
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TeamsMultiSelect(
                                  allTeams: ['10am', '11am', 'Tier II', 'Traditionz', 'IFDE', '2pm'],
                                  selectedTeams: statusTeams.teams,
                                  onChanged: (teams) {
                                    setState(() => statusTeams.teams = teams);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    _selectedDanceIds.remove(dance.id);
                                    danceStatusMap.remove(dance.id);
                                  });
                                },
                              ),
                            ],
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

class TeamsMultiSelect extends StatefulWidget {
  final List<String> allTeams;
  final Set<String> selectedTeams;
  final ValueChanged<Set<String>> onChanged;

  const TeamsMultiSelect({super.key, required this.allTeams, required this.selectedTeams, required this.onChanged});

  @override
  State<TeamsMultiSelect> createState() => _TeamsMultiSelectState();
}

class _TeamsMultiSelectState extends State<TeamsMultiSelect> {
  late Set<String> selected;

  @override
  void initState() {
    super.initState();
    selected = Set.from(widget.selectedTeams);
  }

  void _openDialog() async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        final tempSelected = Set<String>.from(selected);
        return AlertDialog(
          title: const Text('Select Teams'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: widget.allTeams.map((team) {
                return CheckboxListTile(
                  title: Text(team),
                  value: tempSelected.contains(team),
                  onChanged: (bool? val) {
                    setState(() {
                      if (val == true) {
                        tempSelected.add(team);
                      } else {
                        tempSelected.remove(team);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(tempSelected), child: const Text('OK')),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => selected = result);
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = selected.isEmpty ? 'Select Teams' : selected.join(', ');
    return GestureDetector(
      onTap: _openDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
        ),
        constraints: const BoxConstraints(maxWidth: 150),
        child: Text(
          display.length > 20 ? '${display.substring(0, 17)}...' : display,
          style: TextStyle(
            color: selected.isEmpty ? Colors.grey.shade600 : Colors.black,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
