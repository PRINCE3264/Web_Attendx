import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import 'custom_widgets.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _departmentController;
  late TextEditingController _avatarUrlController;

  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _departmentController = TextEditingController(text: user?.department ?? '');
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotoFromSource(ImageSource source) async {
    setState(() => _isUploadingPhoto = true);
    try {
      final storage = StorageService();
      final photoFile = source == ImageSource.gallery
          ? await storage.pickPhotoFromGallery()
          : await storage.pickPhotoFromCamera();
      if (photoFile != null) {
        final bytes = await photoFile.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _avatarUrlController.text = base64Image;
        });
      }
    } catch (e) {
      debugPrint("Photo pick error: $e");
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _showPhotoSourcePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Profile Photo Source',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textMainLight,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
                ),
                title: Text(
                  'Choose from Gallery 🖼️',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Select existing photo from phone gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhotoFromSource(ImageSource.gallery);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppTheme.success),
                ),
                title: Text(
                  'Take Photo with Camera 📷',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Capture new photo using camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhotoFromSource(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.updateMyProfile(
      newName: _nameController.text.trim(),
      newEmail: _emailController.text.trim(),
      newDepartment: _departmentController.text.trim(),
      newAvatarUrl: _avatarUrlController.text.trim().isNotEmpty ? _avatarUrlController.text.trim() : null,
    );

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Failed to update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarUrl = _avatarUrlController.text.trim();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Edit Profile Information',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textMainLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Avatar Photo Picker Preview
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _isUploadingPhoto
                            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                            : PhotoDisplayWidget(
                                photoUrl: avatarUrl.isNotEmpty ? avatarUrl : auth.currentUser?.avatarUrl,
                                size: 90,
                                borderRadius: 45,
                              ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: AppTheme.primary,
                        shape: const CircleBorder(),
                        elevation: 4,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _showPhotoSourcePicker,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _showPhotoSourcePicker,
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Change Photo (Camera / Phone Gallery)'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
              ),
              const SizedBox(height: 14),

              // Email Address Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || !v.contains('@') ? 'Valid email is required' : null,
              ),
              const SizedBox(height: 14),

              // Department Field
              TextFormField(
                controller: _departmentController,
                decoration: InputDecoration(
                  labelText: 'Department',
                  prefixIcon: const Icon(Icons.business_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),

              // Custom Avatar URL Field (Optional)
              TextFormField(
                controller: _avatarUrlController,
                decoration: InputDecoration(
                  labelText: 'Or Paste Photo URL (Optional)',
                  prefixIcon: const Icon(Icons.link_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'https://example.com/my-photo.jpg',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Note: System role and Employee ID are locked by Organization Policy.',
                style: GoogleFonts.inter(fontSize: 11.5, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: auth.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'SAVE PROFILE CHANGES',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
