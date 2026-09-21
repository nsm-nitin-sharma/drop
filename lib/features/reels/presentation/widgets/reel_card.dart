import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/monochrome_avatar.dart';
import '../../../feed/domain/entities/post_entity.dart';

class ReelCard extends StatefulWidget {
  final PostEntity post;
  final VoidCallback onLikeToggle;
  final VoidCallback onCommentTap;

  const ReelCard({
    super.key,
    required this.post,
    required this.onLikeToggle,
    required this.onCommentTap,
  });

  @override
  State<ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<ReelCard> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _showMuteOverlay = false;
  bool _showHeartAnimation = false;

  late AnimationController _heartAnimController;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.post.mediaUrls.isNotEmpty) {
      _initVideoPlayer(widget.post.mediaUrls.first);
    }
  }

  Future<void> _initVideoPlayer(String videoUrl) async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();
      await _controller!.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (_) {}
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_controller == null || !_isInitialized) return;
    if (info.visibleFraction >= 0.6) {
      _controller!.play();
    } else {
      _controller!.pause();
    }
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
      _showMuteOverlay = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showMuteOverlay = false;
        });
      }
    });
  }

  void _onDoubleTapLike() {
    widget.onLikeToggle();
    setState(() {
      _showHeartAnimation = true;
    });
    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _showHeartAnimation = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('reel_${widget.post.postId}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: _toggleMute,
        onDoubleTap: _onDoubleTapLike,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Background Player
            _isInitialized && _controller != null
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                : Container(
                    color: AppColors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    ),
                  ),

            // Subtle Mute Overlay Indicator
            if (_showMuteOverlay)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.overlayDark,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: AppColors.white,
                    size: 32,
                  ),
                ),
              ),

            // Double Tap Heart Pop Animation
            if (_showHeartAnimation)
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.5, end: 1.4).animate(
                    CurvedAnimation(
                      parent: _heartAnimController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppColors.heartRed,
                    size: 100,
                  ),
                ),
              ),

            // Bottom Gradient Overlay for Details
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 250,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, AppColors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Author Details Overlay
            Positioned(
              bottom: 24,
              left: 16,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      MonochromeAvatar(
                        photoUrl: widget.post.authorPhotoUrl,
                        radius: 18,
                        fallbackInitial: widget.post.authorHandle,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '@${widget.post.authorHandle}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.post.caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons Overlay (Right side)
            Positioned(
              bottom: 30,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Like Button
                  IconButton(
                    icon: Icon(
                      widget.post.isLikedByCurrentUser
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.post.isLikedByCurrentUser
                          ? AppColors.heartRed
                          : AppColors.white,
                      size: 32,
                    ),
                    onPressed: widget.onLikeToggle,
                  ),
                  Text(
                    '${widget.post.likesCount}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comment Button
                  IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.white,
                      size: 28,
                    ),
                    onPressed: widget.onCommentTap,
                  ),
                  Text(
                    '${widget.post.commentsCount}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
