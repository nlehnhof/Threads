import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:raw_threads/classes/main_classes/shows.dart';

class NewShow extends StatefulWidget {
  final Function(Shows show) onSaveShow;
  final Shows? existingShow;

  const NewShow({super.key, required this.onSaveShow, this.existingShow});

  @override
  State<NewShow> createState() => _NewShowState();
}

class _NewShowState extends State<NewShow> {
  late TextEditingController _titleController;
  late TextEditingController _datesController;
  late TextEditingController _locationController;
  late TextEditingController _techController;
  late TextEditingController _dressController;
  late Category _selectedCategory;
  final _focusNode = FocusNode();
  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingShow?.title ?? '');
    _datesController = TextEditingController(text: widget.existingShow?.dates ?? '');
    _locationController = TextEditingController(text: widget.existingShow?.location ?? '');
    _techController = TextEditingController(text: widget.existingShow?.tech ?? '');
    _dressController = TextEditingController(text: widget.existingShow?.dress ?? '');
    _selectedCategory = widget.existingShow?.category ?? Category.ifde;
  }

  Future<void> _submitShowData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final adminId = user.uid;
    final showId = widget.existingShow?.id ?? uuid.v4();

    final newShow = Shows(
      id: showId,
      title: _titleController.text,
      dates: _datesController.text,
      location: _locationController.text,
      dress: _dressController.text,
      tech: _techController.text,
      adminId: adminId,
      category: _selectedCategory,
      danceIds: widget.existingShow?.danceIds ?? [],
    );

    final showRef = FirebaseDatabase.instance.ref('admins/$adminId/shows/${newShow.id}');
    await showRef.set(newShow.toJson()); // ← make sure this method exists

    widget.onSaveShow(newShow);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _datesController.dispose();
    _locationController.dispose();
    _techController.dispose();
    _dressController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingShow != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isEditing ? 'Edit Show' : 'Add New Show',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: _titleController,
            maxLength: 50,
            decoration: const InputDecoration(label: Text('Title')),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _datesController,
                  decoration: const InputDecoration(label: Text('Dates')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(label: Text('Location')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dressController,
                  decoration: const InputDecoration(label: Text('Dress Rehearsal')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _techController,
                  decoration: const InputDecoration(label: Text('Tech Rehearsal')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              DropdownButton(
                value: _selectedCategory,
                items: Category.values
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _submitShowData,
                child: Text(isEditing ? 'Save Show' : 'Add Show'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
