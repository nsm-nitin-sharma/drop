import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/monochrome_button.dart';
import '../../../../core/widgets/monochrome_text_field.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../feed/domain/repositories/feed_repository.dart';

class CreatePostPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserHandle;
  final String? currentUserPhotoUrl;
  final FeedRepository feedRepository;
  final VoidCallback onPostCreated;

  const CreatePostPage({
    super.key,
    required this.currentUserId,
    required this.currentUserHandle,
    this.currentUserPhotoUrl,
    required this.feedRepository,
    required this.onPostCreated,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  MediaType _selectedMediaType = MediaType.photo;
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedFile = File(picked.path);
        _selectedMediaType = MediaType.photo;
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedFile = File(picked.path);
        _selectedMediaType = MediaType.video;
      });
    }
  }

  Future<void> _uploadPost() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a photo or video to post'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await widget.feedRepository.createPost(
        authorId: widget.currentUserId,
        authorHandle: widget.currentUserHandle,
        authorPhotoUrl: widget.currentUserPhotoUrl,
        caption: _captionController.text.trim(),
        mediaFiles: [_selectedFile!],
        mediaType: _selectedMediaType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post published successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        widget.onPostCreated();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to publish post. Please try again.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
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
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Selector Preview Box
            GestureDetector(
              onTap: () {
                _showMediaPickerModal(context);
              },
              child: Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: _selectedFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _selectedMediaType == MediaType.photo
                            ? Image.file(_selectedFile!, fit: BoxFit.cover)
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_library, size: 64, color: primaryColor),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Video Selected',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 48, color: textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to select photo or video',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Caption Input
            MonochromeTextField(
              controller: _captionController,
              label: 'Caption',
              hint: 'Write a caption...',
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Publish Button
            MonochromeButton(
              label: 'Share Post',
              isLoading: _isUploading,
              onPressed: _uploadPost,
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaPickerModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: primaryColor),
                title: Text('Select Photo from Gallery', style: TextStyle(color: primaryColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.video_collection, color: primaryColor),
                title: Text('Select Video from Gallery', style: TextStyle(color: primaryColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
