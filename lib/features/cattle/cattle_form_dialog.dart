import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_colors.dart';
import '../../config/app_routes.dart';
import '../../config/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../models/cattle_model.dart';
import '../../repositories/cattle_repository.dart';
import '../../services/image_storage_service.dart';
import '../../services/session_service.dart';

class CattleFormDialog extends StatefulWidget {
  const CattleFormDialog({super.key, this.cattle});

  final CattleModel? cattle;

  @override
  State<CattleFormDialog> createState() => _CattleFormDialogState();
}

class _CattleFormDialogState extends State<CattleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();
  final _imagePicker = ImagePicker();

  String _selectedBreed = 'Jersey';
  String _selectedSex = 'Female';
  String? _imagePath;
  Uint8List? _imageBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.cattle != null) {
      final cattle = widget.cattle!;
      _nameController.text = cattle.name;
      _ageController.text = cattle.age?.toString() ?? '';
      _notesController.text = cattle.notes ?? '';
      _selectedBreed = cattle.breed ?? 'Jersey';
      _selectedSex = cattle.sex ?? 'Female';
      _imagePath = cattle.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        // On web XFile.path may be empty; store a temporary web key for preview
        _imagePath = 'web://preview';
      });
    } else {
      setState(() {
        _imagePath = file.path;
      });
    }
  }

  Future<void> _saveCattle() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final userId = await SessionService.instance.getSessionUserId();
    if (userId == null || userId <= 0) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.auth, (route) => false);
      }
      return;
    }

    final now = DateTime.now();
    final imageService = ImageStorageService();
    String? savedImagePath;

    if (_imagePath != null && _imagePath!.isNotEmpty) {
      if (kIsWeb) {
        savedImagePath = await imageService.saveImage(
          fileName: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          sourcePath: _imagePath!,
          bytes: _imageBytes,
        );
      } else {
        savedImagePath = await imageService.saveImage(
          fileName: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          sourcePath: _imagePath!,
        );
      }
    }

    final existingImage = widget.cattle?.imagePath;
    if (widget.cattle != null && existingImage != null && existingImage.isNotEmpty && _imagePath != null) {
      final file = File(existingImage);
      if (await file.exists()) {
        await file.delete();
      }
    }

    final cattle = CattleModel(
      id: widget.cattle?.id,
      userId: userId,
      name: _nameController.text.trim(),
      breed: _selectedBreed,
      age: int.tryParse(_ageController.text.trim()),
      sex: _selectedSex,
      imagePath: savedImagePath ?? widget.cattle?.imagePath,
      notes: _notesController.text.trim(),
      createdAt: widget.cattle?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final repository = CattleRepository();
      await repository.saveCattle(cattle);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save cattle record.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.cattle == null ? 'Register Cattle' : 'Edit Cattle',
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderStrong, width: 2),
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: kIsWeb
                                ? (_imageBytes != null
                                    ? Image.memory(
                                        _imageBytes!,
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      )
                                    : FutureBuilder<Uint8List?>(
                                        future: ImageStorageService().loadImageBytes(_imagePath!),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                                          final bytes = snapshot.data;
                                          if (bytes == null) {
                                            return Container(
                                              color: AppColors.primarySoft,
                                              child: const Center(child: Icon(Icons.pets_outlined, size: 48, color: AppColors.primary)),
                                            );
                                          }
                                          return Image.memory(bytes, width: double.infinity, height: 180, fit: BoxFit.cover);
                                        },
                                      ))
                                : Image.file(
                                    File(_imagePath!),
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.primary),
                                SizedBox(height: 10),
                                Text('Choose Photo', style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Cattle ID / Name',
                        hintText: 'COW-001',
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Cattle name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedBreed,
                        items: const [
                          DropdownMenuItem(value: 'Jersey', child: Text('Jersey')),
                          DropdownMenuItem(value: 'Holstein Friesian', child: Text('Holstein Friesian')),
                          DropdownMenuItem(value: 'Gir', child: Text('Gir')),
                          DropdownMenuItem(value: 'Sahiwal', child: Text('Sahiwal')),
                          DropdownMenuItem(value: 'Red Sindhi', child: Text('Red Sindhi')),
                          DropdownMenuItem(value: 'Kangayam', child: Text('Kangayam')),
                          DropdownMenuItem(value: 'Crossbreed', child: Text('Crossbreed')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedBreed = value);
                        },
                        decoration: const InputDecoration(labelText: 'Breed'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Age',
                        hintText: 'Years',
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedSex,
                        items: const [
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedSex = value);
                        },
                        decoration: const InputDecoration(labelText: 'Sex'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Optional health / identification notes',
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: _isSaving ? 'Saving...' : (widget.cattle == null ? 'Add Cattle' : 'Save Changes'),
                    onPressed: _isSaving ? null : _saveCattle,
                    isLoading: _isSaving,
                    fullWidth: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
