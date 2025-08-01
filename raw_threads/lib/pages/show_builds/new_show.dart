import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/shows.dart';

// import 'package:threadline_initial/logins/users.dart';
class NewShow extends StatefulWidget {
  final Function(Shows show) onSaveShow;
  final Shows? existingShow;

  const NewShow({super.key, required this.onSaveShow, this.existingShow});

  @override
  State<NewShow> createState() {
    return _NewShowState();
  }
}

class _NewShowState extends State<NewShow> {
  late TextEditingController _titleController;
  late TextEditingController _datesController;
  late TextEditingController _locationController;
  late TextEditingController _techController;
  late TextEditingController _dressController;
  late Category _selectedCategory;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingShow?.title ?? '',
    );
    _datesController = TextEditingController(
      text: widget.existingShow?.dates ?? '',
    );
    _locationController = TextEditingController(
      text: widget.existingShow?.location ?? '',
    );
    _techController = TextEditingController(
      text: widget.existingShow?.tech ?? '',
    );
    _dressController = TextEditingController(
      text: widget.existingShow?.dress ?? '',
    );
    _selectedCategory = widget.existingShow?.category ?? Category.IFDE;
  }

  void _submitShowData() {
    final newShow = Shows(
      id: widget.existingShow?.id ?? uuid.v4(),
      title: _titleController.text,
      dates: _datesController.text,
      location: _locationController.text,
      dress: _dressController.text,
      tech: _techController.text,
      category: _selectedCategory,
      danceIds: widget.existingShow?.danceIds ?? [],
    );
    widget.onSaveShow(newShow);
    Navigator.of(context).pop();
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
            decoration: const InputDecoration(
              label: Text('Title'),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _datesController,
                  decoration: const InputDecoration(
                    label: Text('Dates'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    label: Text('Location'),
                  ),
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
                  decoration: const InputDecoration(
                    label: Text('Dress Rehearsal'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _techController,
                  decoration: const InputDecoration(
                    label: Text('Tech Rehearsal'),
                  ),
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
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          category.name.toUpperCase(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
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