import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/account/app_state.dart';
import 'package:provider/provider.dart';

import 'package:raw_threads/services/storage_service.dart'; // import the helper

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
  final availableController = TextEditingController();
  final countryController = TextEditingController();
  final regionController = TextEditingController();

  File? selectedLeftImage;
  File? selectedRightImage;

  bool isUploadingLeft = false;
  bool isUploadingRight = false;

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
      // We will ignore local File paths now; always upload new images
    }

    titleController.addListener(_onTextChanged);
    totalController.addListener(_onTextChanged);
    availableController.addListener(_onTextChanged);
    countryController.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {}); // triggers form validation rebuild

  @override
  void dispose() {
    titleController.dispose();
    totalController.dispose();
    availableController.dispose();
    countryController.dispose();
    regionController.dispose();
    super.dispose();
  }

  /// Pick image from gallery and set local file
  Future<void> pickImage(bool isLeft) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isLeft) selectedLeftImage = File(picked.path);
        else selectedRightImage = File(picked.path);
      });
    }
  }

  bool get isFormValid {
    return titleController.text.trim().isNotEmpty &&
        totalController.text.trim().isNotEmpty &&
        availableController.text.trim().isNotEmpty &&
        countryController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final adminId = context.read<AppState>().adminId;
    return Dialog(
      backgroundColor: const Color(0xFFEFF2EF),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Add costume', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, fontFamily: 'Georgia')),
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
                          image: selectedLeftImage != null ? DecorationImage(
                            image: FileImage(selectedLeftImage!),
                            fit: BoxFit.cover,
                          ) : null,
                        ),
                        child: selectedLeftImage == null
                            ? const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 30))
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
                          image: selectedRightImage != null ? DecorationImage(
                            image: FileImage(selectedRightImage!),
                            fit: BoxFit.cover,
                          ) : null,
                        ),
                        child: selectedRightImage == null
                            ? const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 30))
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Text fields for title, total, available, country, region
              _buildTextField(titleController, 'Costume name'),
              const SizedBox(height: 12),
              _buildTextField(totalController, 'How many full costumes?', isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(availableController, 'How many are currently available?', isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(countryController, 'Country of origin'),
              const SizedBox(height: 12),
              _buildTextField(regionController, 'Region'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isFormValid && adminId != null
                      ? () async {
                          String? leftUrl, rightUrl;
                          if (selectedLeftImage != null) {
                            setState(() => isUploadingLeft = true);
                            leftUrl = await StorageHelper.uploadFile(
                              storagePath: 'admins/$adminId/dances/',
                              file: selectedLeftImage!,
                            );
                            setState(() => isUploadingLeft = false);
                          }
                          if (selectedRightImage != null) {
                            setState(() => isUploadingRight = true);
                            rightUrl = await StorageHelper.uploadFile(
                              storagePath: 'admins/$adminId/dances/',
                              file: selectedRightImage!,
                            );
                            setState(() => isUploadingRight = false);
                          }

                          final danceToSave = widget.dance != null
                              ? widget.dance!.copyWith(
                                  title: titleController.text.trim(),
                                  country: countryController.text.trim(),
                                  available: int.tryParse(availableController.text.trim()) ?? 0,
                                  total: int.tryParse(totalController.text.trim()) ?? 0,
                                  leftImagePath: leftUrl ?? widget.dance!.leftImagePath,
                                  rightImagePath: rightUrl ?? widget.dance!.rightImagePath,
                                )
                              : Dances(
                                  id: uuid.v4(),
                                  title: titleController.text.trim(),
                                  country: countryController.text.trim(),
                                  available: int.tryParse(availableController.text.trim()) ?? 0,
                                  total: int.tryParse(totalController.text.trim()) ?? 0,
                                  category: Category.prepped,
                                  leftImagePath: leftUrl,
                                  rightImagePath: rightUrl,
                                );

                          Navigator.pop(context);
                          widget.onSubmit(danceToSave);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: myColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: (isUploadingLeft || isUploadingRight)
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Continue', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }
}
