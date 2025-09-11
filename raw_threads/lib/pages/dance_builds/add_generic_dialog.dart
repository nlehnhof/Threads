import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/account/app_state.dart';
import 'package:raw_threads/services/storage_service.dart';

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
  String? leftImageUrl;
  String? rightImageUrl;

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
      regionController.text = dance.region;
      leftImageUrl = dance.leftImagePath;
      rightImageUrl = dance.rightImagePath;
    }

    titleController.addListener(_onTextChanged);
    totalController.addListener(_onTextChanged);
    availableController.addListener(_onTextChanged);
    countryController.addListener(_onTextChanged);

    // Ensure there is always a placeholder path
    leftImageUrl ??= 'assets/threadline_logo.png';
    rightImageUrl ??= 'assets/threadline_logo.png';
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    titleController.dispose();
    totalController.dispose();
    availableController.dispose();
    countryController.dispose();
    regionController.dispose();
    super.dispose();
  }

  bool get isFormValid =>
      titleController.text.trim().isNotEmpty &&
      totalController.text.trim().isNotEmpty &&
      availableController.text.trim().isNotEmpty &&
      countryController.text.trim().isNotEmpty &&
      leftImageUrl != null &&
      rightImageUrl != null;

  Future<void> _pickImage(bool isLeft) async {
    final adminId = context.read<AppState>().adminId;
    if (adminId == null) return;

    final danceId = widget.dance?.id ?? uuid.v4();
    final pickedFile = await StorageHelper.pickFile(fromCamera: false);
    if (pickedFile == null) return;

    setState(() {
      if (isLeft) {
        selectedLeftImage = pickedFile;
      } else {
        selectedRightImage = pickedFile;
      }
    });

    // Start background upload
    if (isLeft) {
      isUploadingLeft = true;
    } else {
      isUploadingRight = true;
    }
    setState(() {});

    final uploadedUrl = await StorageHelper.uploadFile(
      file: pickedFile,
      storagePath: 'admins/$adminId/dances/$danceId/${isLeft ? 'left' : 'right'}',
    );

    if (uploadedUrl != null) {
      setState(() {
        if (isLeft) {
          leftImageUrl = uploadedUrl;
          selectedLeftImage = null;
          isUploadingLeft = false;
        } else {
          rightImageUrl = uploadedUrl;
          selectedRightImage = null;
          isUploadingRight = false;
        }
      });
    } else {
      // Upload failed, keep local file but mark as not uploading
      setState(() {
        if (isLeft) {
          isUploadingLeft = false;
        } else {
          isUploadingRight = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminId = Provider.of<AppState>(context, listen: false).adminId;

    return Dialog(
      backgroundColor: const Color(0xFFEFF2EF),
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
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
              const Text(
                'Add costume',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w600, fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildImageSelector(true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildImageSelector(false)),
                ],
              ),
              const SizedBox(height: 16),
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
                      ? () {
                          final danceId = widget.dance?.id ?? uuid.v4();
                          final danceToSave = widget.dance != null
                              ? widget.dance!.copyWith(
                                  title: titleController.text.trim(),
                                  country: countryController.text.trim(),
                                  region: regionController.text.trim(),
                                  available: int.tryParse(availableController.text.trim()) ?? 0,
                                  total: int.tryParse(totalController.text.trim()) ?? 0,
                                  leftImagePath: leftImageUrl,
                                  rightImagePath: rightImageUrl,
                                )
                              : Dances(
                                  id: danceId,
                                  title: titleController.text.trim(),
                                  country: countryController.text.trim(),
                                  region: regionController.text.trim(),
                                  available: int.tryParse(availableController.text.trim()) ?? 0,
                                  total: int.tryParse(totalController.text.trim()) ?? 0,
                                  category: Category.prepped,
                                  leftImagePath: leftImageUrl,
                                  rightImagePath: rightImageUrl,
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
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Continue', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector(bool isLeft) {
    final localFile = isLeft ? selectedLeftImage : selectedRightImage;
    final imageUrl = isLeft ? leftImageUrl : rightImageUrl;

    Widget imageWidget;

    if (localFile != null) {
      imageWidget = Image.file(localFile, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl.startsWith('http')) {
      imageWidget = Image.network(imageUrl, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl.startsWith('assets/')) {
      imageWidget = Image.asset(imageUrl, fit: BoxFit.cover);
    } else {
      imageWidget = const Icon(Icons.image_outlined, color: Colors.grey, size: 30);
    }

    return GestureDetector(
      onTap: () => _pickImage(isLeft),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            if ((isLeft ? isUploadingLeft : isUploadingRight))
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
