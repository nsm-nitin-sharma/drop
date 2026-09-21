import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/monochrome_avatar.dart';
import '../../../../core/widgets/monochrome_button.dart';
import '../../../../core/widgets/monochrome_text_field.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class EditProfileSheet extends StatefulWidget {
  final UserEntity currentUser;
  final ProfileRepository profileRepository;

  const EditProfileSheet({
    super.key,
    required this.currentUser,
    required this.profileRepository,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  File? _selectedAvatar;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.currentUser.displayName);
    _bioController = TextEditingController(text: widget.currentUser.bio);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _selectedAvatar = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await widget.profileRepository.updateUserProfile(
        uid: widget.currentUser.uid,
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarFile: _selectedAvatar,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),

          // Avatar Selector
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _selectedAvatar != null
                      ? CircleAvatar(
                          radius: 40,
                          backgroundImage: FileImage(_selectedAvatar!),
                        )
                      : MonochromeAvatar(
                          photoUrl: widget.currentUser.photoUrl,
                          radius: 40,
                          fallbackInitial: widget.currentUser.handle,
                        ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.black.withValues(alpha: 0.4),
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.white, size: 24),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          MonochromeTextField(
            controller: _displayNameController,
            label: 'Display Name',
            hint: 'Your Name',
          ),
          const SizedBox(height: 16),

          MonochromeTextField(
            controller: _bioController,
            label: 'Bio',
            hint: 'Write something about yourself...',
            maxLines: 3,
          ),
          const SizedBox(height: 28),

          MonochromeButton(
            label: 'Save Changes',
            isLoading: _isSaving,
            onPressed: _saveProfile,
          ),
        ],
      ),
    );
  }
}
