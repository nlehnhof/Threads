import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/assignments.dart';
import 'package:uuid/uuid.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';

class AddEditAssignments extends StatefulWidget {
  final Assignments? existing;
  final bool allowDelete;
  final Function(Assignments) onSave;
  final CostumePiece costume;

  const AddEditAssignments({
    super.key,
    this.existing,
    required this.allowDelete,
    required this.onSave,
    required this.costume,
  });

  @override
  State<AddEditAssignments> createState() => _AddEditAssignmentsState();
}

class _AddEditAssignmentsState extends State<AddEditAssignments> {
  final uuid = Uuid();

  late TextEditingController _numberController;
  late TextEditingController _sizeController;
  late TextEditingController _userController;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    _numberController = TextEditingController(text: existing?.number ?? '');
    _sizeController = TextEditingController(text: existing?.size ?? '');
    _userController = TextEditingController(text: existing?.user ?? '');
  }

  @override
  void dispose() {
    _numberController.dispose();
    _sizeController.dispose();
    _userController.dispose();
    super.dispose();
  }

  Future<void> _onSavePressed() async {
    final number = _numberController.text.trim();
    final size = _sizeController.text.trim();
    final user = _userController.text.trim();

    final newAssignment = Assignments(
      id: widget.existing?.id ?? uuid.v4(),
      title: widget.costume.title,
      size: size,
      number: number,
      user: user,
    );

    await widget.onSave(newAssignment);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Assignment' : 'Edit Assignment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(labelText: 'Number'),
            ),
            TextField(
              controller: _sizeController,
              decoration: const InputDecoration(labelText: 'Size'),
            ),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: 'User'),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.allowDelete)
          TextButton(
            onPressed: () => Navigator.of(context).pop(null), // signal delete
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: _onSavePressed,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
