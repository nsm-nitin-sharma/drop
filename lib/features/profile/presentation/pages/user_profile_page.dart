import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/monochrome_avatar.dart';
import '../../../../core/widgets/monochrome_button.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../feed/domain/repositories/feed_repository.dart';
import '../../../social_graph/domain/repositories/social_graph_repository.dart';
import '../../domain/repositories/profile_repository.dart';

class UserProfilePage extends StatefulWidget {
  final UserEntity targetUser;
  final String currentUserId;
  final ProfileRepository profileRepository;
  final SocialGraphRepository socialGraphRepository;
  final FeedRepository feedRepository;

  const UserProfilePage({
    super.key,
    required this.targetUser,
    required this.currentUserId,
    required this.profileRepository,
    required this.socialGraphRepository,
    required this.feedRepository,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isFollowing = false;
  bool _isTogglingFollow = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final isSelf = widget.currentUserId == widget.targetUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('@${widget.targetUser.handle}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<UserEntity>(
        stream: widget.profileRepository.streamUserProfile(widget.targetUser.uid),
        initialData: widget.targetUser,
        builder: (context, profileSnap) {
          final user = profileSnap.data ?? widget.targetUser;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Stats Row
                Row(
                  children: [
                    MonochromeAvatar(
                      photoUrl: user.photoUrl,
                      radius: 36,
                      fallbackInitial: user.handle,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(context, '${user.postsCount}', 'Posts'),
                          _buildStatColumn(context, '${user.followersCount}', 'Followers'),
                          _buildStatColumn(context, '${user.followingCount}', 'Following'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name & Bio
                Text(
                  user.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.bio.isNotEmpty ? user.bio : 'No bio yet.',
                  style: TextStyle(color: textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Follow / Unfollow Action Button (if not self)
                if (!isSelf)
                  StreamBuilder<bool>(
                    stream: widget.socialGraphRepository.isFollowingStream(
                      currentUid: widget.currentUserId,
                      targetUid: user.uid,
                    ),
                    builder: (context, followSnap) {
                      _isFollowing = followSnap.data ?? false;

                      return MonochromeButton(
                        label: _isFollowing ? 'Following' : 'Follow',
                        isOutlined: _isFollowing,
                        isLoading: _isTogglingFollow,
                        onPressed: () async {
                          setState(() {
                            _isTogglingFollow = true;
                          });
                          if (_isFollowing) {
                            await widget.socialGraphRepository.unfollowUser(
                              currentUid: widget.currentUserId,
                              targetUid: user.uid,
                            );
                          } else {
                            await widget.socialGraphRepository.followUser(
                              currentUid: widget.currentUserId,
                              targetUid: user.uid,
                            );
                          }
                          if (mounted) {
                            setState(() {
                              _isTogglingFollow = false;
                            });
                          }
                        },
                      );
                    },
                  ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // User Posts Grid
                StreamBuilder<List<PostEntity>>(
                  stream: widget.feedRepository.getUserPostsStream(
                    targetUserId: user.uid,
                    currentUserId: widget.currentUserId,
                  ),
                  builder: (context, postsSnap) {
                    final posts = postsSnap.data ?? [];
                    if (posts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'No posts yet.',
                            style: TextStyle(color: textSecondary, fontSize: 14),
                          ),
                        ),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final mediaUrl = post.mediaUrls.isNotEmpty ? post.mediaUrls.first : '';
                        return Container(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          child: mediaUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: mediaUrl,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.movie_outlined),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String count, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: textSecondary),
        ),
      ],
    );
  }
}
