import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';

final uuid = Uuid();

class AddGenericDialog extends StatefulWidget {
  final Function(Dances) onSubmit;
  final Dances? dance;

  const AddGenericDialog({super.key, required this.onSubmit, this.dance});

  @override
  State<AddGenericDialog> createState() => _AddGenericDialogState();
}

class _AddGenericDialogState extends State<AddGenericDialog> {
  final titleController = TextEditingController();
  final totalController = TextEditingController();
  final countryController = TextEditingController();
  final regionController = TextEditingController();
  final availableController = TextEditingController();

  File? selectedLeftImage;
  File? selectedRightImage;

  @override
  void initState() {
    super.initState();
    if (widget.dance != null) {
      final dance = widget.dance!;
      titleController.text = dance.title;
      totalController.text = dance.total.toString();
      availableController.text = dance.available.toString();
      countryController.text = dance.country;
      regionController.text = '';
      selectedLeftImage = dance.leftImagePath != null ? File(dance.leftImagePath!) : null;
      selectedRightImage = dance.rightImagePath != null ? File(dance.rightImagePath!) : null;
    } else {
      titleController.text = '';
      totalController.text = '';
      availableController.text = '';
      countryController.text = '';
      regionController.text = '';
      selectedLeftImage = null;
      selectedRightImage = null;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    totalController.dispose();
    availableController.dispose();
    countryController.dispose();
    regionController.dispose();
    super.dispose();
  }

  Future<void> pickImage(bool isLeft) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isLeft) {
          selectedLeftImage = File(picked.path);
        } else {
          selectedRightImage = File(picked.path);
        }
      });
    }
  }

  bool get isFormValid {
    final valid = titleController.text.trim().isNotEmpty &&
        totalController.text.trim().isNotEmpty &&
        availableController.text.trim().isNotEmpty &&
        countryController.text.trim().isNotEmpty;
    return valid;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFEFF2EF),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add costume',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => pickImage(true),
                      child: Container(
                        height: 150,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          image: selectedLeftImage != null
                              ? DecorationImage(
                                  image: FileImage(selectedLeftImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: selectedLeftImage == null
                            ? const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey,
                                  size: 30,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => pickImage(false),
                      child: Container(
                        height: 150,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          image: selectedRightImage != null
                              ? DecorationImage(
                                  image: FileImage(selectedRightImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: selectedRightImage == null
                            ? const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey,
                                  size: 30,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Costume name",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "How many full costumes do you have?",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: availableController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "How many are currently available?",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countryController,
                decoration: const InputDecoration(
                  labelText: "Country of origin",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: regionController,
                decoration: const InputDecoration(
                  labelText: "Region",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isFormValid
                      ? () {
                          final danceToSave = widget.dance != null
                            ? widget.dance!.copyWith(
                                title: titleController.text.trim(),
                                country: countryController.text.trim(),
                                available: int.tryParse(availableController.text.trim()) ?? 0,
                                total: int.tryParse(totalController.text.trim()) ?? 0,
                                leftImagePath: selectedLeftImage?.path,
                                rightImagePath: selectedRightImage?.path,
                              )
                            : Dances(
                              id: uuid.v4(),
                              title: titleController.text.trim(),
                              country: countryController.text.trim(),
                              available: int.tryParse(availableController.text.trim()) ?? 0,
                              total: int.tryParse(totalController.text.trim()) ?? 0,
                              category: Category.prepped,
                              leftImagePath: selectedLeftImage?.path,
                              rightImagePath: selectedRightImage?.path,
                            );
                          Navigator.pop(context);
                          widget.onSubmit(danceToSave);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9DA99B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
