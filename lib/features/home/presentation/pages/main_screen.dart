import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/floating_nav_bar.dart';
import '../../../../core/widgets/monochrome_avatar.dart';
import '../../../../core/widgets/monochrome_button.dart';
import '../../../../core/widgets/smart_image.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../../feed/data/repositories/feed_repository_impl.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../feed/domain/repositories/feed_repository.dart';
import '../../../feed/presentation/widgets/comments_bottom_sheet.dart';
import '../../../media_post/presentation/pages/create_post_page.dart';
import '../../../messaging/data/repositories/messaging_repository_impl.dart';
import '../../../messaging/domain/repositories/messaging_repository.dart';
import '../../../messaging/presentation/pages/conversations_page.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';
import '../../../profile/presentation/widgets/edit_profile_sheet.dart';
import '../../../reels/presentation/widgets/reel_card.dart';
import '../../../search/data/repositories/search_repository_impl.dart';
import '../../../search/domain/repositories/search_repository.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../social_graph/data/repositories/social_graph_repository_impl.dart';
import '../../../social_graph/domain/repositories/social_graph_repository.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late FeedRepository _feedRepository;
  late SearchRepository _searchRepository;
  late SocialGraphRepository _socialGraphRepository;
  late ProfileRepository _profileRepository;
  late MessagingRepository _messagingRepository;

  @override
  void initState() {
    super.initState();
    _feedRepository = FeedRepositoryImpl(FeedRemoteDataSourceImpl());
    _searchRepository = SearchRepositoryImpl();
    _socialGraphRepository = SocialGraphRepositoryImpl();
    _profileRepository = ProfileRepositoryImpl();
    _messagingRepository = MessagingRepositoryImpl();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final List<Widget> pages = [
      // 0: Feed Screen
      _FeedTabWidget(
        key: const PageStorageKey('FeedTab'),
        currentUser: currentUser,
        feedRepository: _feedRepository,
        messagingRepository: _messagingRepository,
        profileRepository: _profileRepository,
        onAddPostPressed: () => setState(() => _selectedIndex = 2),
      ),

      // 1: Search Screen
      SearchPage(
        searchRepository: _searchRepository,
        onUserSelected: (targetUser) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfilePage(
                targetUser: targetUser,
                currentUserId: currentUser.uid,
                profileRepository: _profileRepository,
                socialGraphRepository: _socialGraphRepository,
                feedRepository: _feedRepository,
                messagingRepository: _messagingRepository,
              ),
            ),
          );
        },
      ),

      // 2: Post Create Screen
      CreatePostPage(
        currentUserId: currentUser.uid,
        currentUserHandle: currentUser.handle,
        currentUserPhotoUrl: currentUser.photoUrl,
        feedRepository: _feedRepository,
        onPostCreated: () {
          setState(() {
            _selectedIndex = 0; // Switch to Feed tab after post
          });
        },
      ),

      // 3: Reels Screen
      _ReelsTabWidget(
        key: const PageStorageKey('ReelsTab'),
        currentUser: currentUser,
        feedRepository: _feedRepository,
      ),

      // 4: Profile Screen
      _ProfileTabWidget(
        key: const PageStorageKey('ProfileTab'),
        currentUser: currentUser,
        feedRepository: _feedRepository,
        profileRepository: _profileRepository,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          FloatingNavBarItem(
            icon: Icons.home_outlined,
            activeIcon: IconData(0xe318, fontFamily: 'MaterialIcons'), // Home filled
            label: 'Feed',
          ),
          FloatingNavBarItem(
            icon: Icons.search_outlined,
            activeIcon: Icons.search,
            label: 'Search',
          ),
          FloatingNavBarItem(
            icon: Icons.add_box_outlined,
            activeIcon: Icons.add_box,
            label: 'Post',
          ),
          FloatingNavBarItem(
            icon: Icons.movie_outlined,
            activeIcon: Icons.movie,
            label: 'Reels',
          ),
          FloatingNavBarItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Persistent Feed Tab keeping scroll state and loaded images in memory
class _FeedTabWidget extends StatefulWidget {
  final UserEntity currentUser;
  final FeedRepository feedRepository;
  final MessagingRepository messagingRepository;
  final ProfileRepository profileRepository;
  final VoidCallback onAddPostPressed;

  const _FeedTabWidget({
    super.key,
    required this.currentUser,
    required this.feedRepository,
    required this.messagingRepository,
    required this.profileRepository,
    required this.onAddPostPressed,
  });

  @override
  State<_FeedTabWidget> createState() => _FeedTabWidgetState();
}

class _FeedTabWidgetState extends State<_FeedTabWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                      ),
                      child: Center(
                        child: Text(
                          'D',
                          style: TextStyle(
                            color: isDark ? AppColors.black : AppColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'D R O P',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        letterSpacing: 4.0,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: widget.onAddPostPressed,
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConversationsPage(
                              currentUser: widget.currentUser,
                              messagingRepository: widget.messagingRepository,
                              profileRepository: widget.profileRepository,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<PostEntity>>(
              stream: widget.feedRepository.getFeedPostsStream(currentUserId: widget.currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 56, color: textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'No posts in feed yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to share a moment on Drop.',
                          style: TextStyle(color: textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        MonochromeButton(
                          label: 'Create Post',
                          width: 160,
                          onPressed: widget.onAddPostPressed,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  key: const PageStorageKey('FeedListView'),
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildPostCard(context, post, widget.currentUser);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, PostEntity post, UserEntity currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final mediaUrl = post.mediaUrls.isNotEmpty ? post.mediaUrls.first : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                MonochromeAvatar(
                  photoUrl: post.authorPhotoUrl,
                  radius: 18,
                  fallbackInitial: post.authorHandle,
                ),
                const SizedBox(width: 10),
                Text(
                  '@${post.authorHandle}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (post.authorId == currentUser.uid)
                  IconButton(
                    icon: Icon(Icons.more_vert, color: textSecondary, size: 20),
                    onPressed: () => _showPostOptionsMenu(context, post, currentUser),
                  ),
              ],
            ),
          ),

          // Post Media
          if (mediaUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: SmartImage(
                  imageUrl: mediaUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Post Actions Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                    color: post.isLikedByCurrentUser ? AppColors.heartRed : primaryColor,
                  ),
                  onPressed: () {
                    widget.feedRepository.toggleLikePost(
                      postId: post.postId,
                      currentUserId: currentUser.uid,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline, color: primaryColor),
                  onPressed: () => _showCommentsSheet(context, post, currentUser),
                ),
              ],
            ),
          ),

          // Likes Count & Caption
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${post.likesCount} likes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (post.caption.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: primaryColor, fontSize: 14),
                      children: [
                        TextSpan(
                          text: '@${post.authorHandle} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: post.caption),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showCommentsSheet(context, post, currentUser),
                  child: Text(
                    post.commentsCount > 0
                        ? 'View all ${post.commentsCount} comments'
                        : 'Add a comment...',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPostOptionsMenu(BuildContext context, PostEntity post, UserEntity currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                title: const Text('Delete Post', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(context, post, currentUser);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, PostEntity post, UserEntity currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          title: Text(
            'Delete Post',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
          ),
          content: Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogContext);
                try {
                  await widget.feedRepository.deletePost(postId: post.postId, authorId: currentUser.uid);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Post deleted successfully.'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete post. Please try again.'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showCommentsSheet(BuildContext context, PostEntity post, UserEntity currentUser) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(
        postId: post.postId,
        currentUserId: currentUser.uid,
        currentUserHandle: currentUser.handle,
        currentUserPhotoUrl: currentUser.photoUrl,
        feedRepository: widget.feedRepository,
      ),
    );
  }
}

/// Persistent Reels Tab Widget
class _ReelsTabWidget extends StatefulWidget {
  final UserEntity currentUser;
  final FeedRepository feedRepository;

  const _ReelsTabWidget({
    super.key,
    required this.currentUser,
    required this.feedRepository,
  });

  @override
  State<_ReelsTabWidget> createState() => _ReelsTabWidgetState();
}

class _ReelsTabWidgetState extends State<_ReelsTabWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textSecondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return StreamBuilder<List<PostEntity>>(
      stream: widget.feedRepository.getFeedPostsStream(currentUserId: widget.currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final allPosts = snapshot.data ?? [];
        final videoPosts = allPosts.where((p) => p.mediaType == MediaType.video).toList();

        if (videoPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.movie_outlined, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'No Reels yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload a video to see it auto-play in Reels!',
                  style: TextStyle(color: textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: videoPosts.length,
          itemBuilder: (context, index) {
            final post = videoPosts[index];
            return ReelCard(
              post: post,
              onLikeToggle: () {
                widget.feedRepository.toggleLikePost(
                  postId: post.postId,
                  currentUserId: widget.currentUser.uid,
                );
              },
              onCommentTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CommentsBottomSheet(
                    postId: post.postId,
                    currentUserId: widget.currentUser.uid,
                    currentUserHandle: widget.currentUser.handle,
                    currentUserPhotoUrl: widget.currentUser.photoUrl,
                    feedRepository: widget.feedRepository,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Persistent Profile Tab Widget
class _ProfileTabWidget extends StatefulWidget {
  final UserEntity currentUser;
  final FeedRepository feedRepository;
  final ProfileRepository profileRepository;

  const _ProfileTabWidget({
    super.key,
    required this.currentUser,
    required this.feedRepository,
    required this.profileRepository,
  });

  @override
  State<_ProfileTabWidget> createState() => _ProfileTabWidgetState();
}

class _ProfileTabWidgetState extends State<_ProfileTabWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return StreamBuilder<UserEntity>(
      stream: widget.profileRepository.streamUserProfile(widget.currentUser.uid),
      initialData: widget.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data ?? widget.currentUser;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '@${user.handle}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        color: primaryColor,
                      ),
                      tooltip: 'Toggle Theme',
                      onPressed: () {
                        final currentMode = context.read<ThemeCubit>().state;
                        final nextMode = currentMode == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.dark;
                        context.read<ThemeCubit>().setThemeMode(nextMode);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Glassmorphic Profile Header Dock
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          MonochromeAvatar(
                            photoUrl: user.photoUrl,
                            radius: 36,
                            fallbackInitial: user.handle,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatColumn(context, '${user.postsCount}', 'Posts'),
                                Container(width: 1, height: 28, color: borderColor),
                                _buildStatColumn(context, '${user.followersCount}', 'Followers'),
                                Container(width: 1, height: 28, color: borderColor),
                                _buildStatColumn(context, '${user.followingCount}', 'Following'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.bio.isNotEmpty ? user.bio : 'Welcome to Drop.',
                        style: TextStyle(color: textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: MonochromeButton(
                              label: 'Edit Profile',
                              isOutlined: true,
                              height: 42,
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => EditProfileSheet(
                                    currentUser: user,
                                    profileRepository: widget.profileRepository,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
                            tooltip: 'Log Out',
                            onPressed: () => _showLogoutConfirmationDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'POSTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // User Posts Grid
                StreamBuilder<List<PostEntity>>(
                  stream: widget.feedRepository.getUserPostsStream(
                    targetUserId: user.uid,
                    currentUserId: user.uid,
                  ),
                  builder: (context, postsSnap) {
                    final posts = postsSnap.data ?? [];
                    if (posts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'No posts created yet.',
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
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final mediaUrl = post.mediaUrls.isNotEmpty ? post.mediaUrls.first : '';
                        return GestureDetector(
                          onLongPress: () {
                            _showPostDeleteOption(context, post, user.uid);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              child: mediaUrl.isNotEmpty
                                  ? SmartImage(
                                      imageUrl: mediaUrl,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.movie_outlined),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPostDeleteOption(BuildContext context, PostEntity post, String currentUserId) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                title: const Text('Delete Post', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  await widget.feedRepository.deletePost(postId: post.postId, authorId: currentUserId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          title: Text(
            'Log Out',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          content: Text(
            'Are you sure you want to log out of Drop?',
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<AuthBloc>().add(AuthSignOutRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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
            fontWeight: FontWeight.w900,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
        ),
      ],
    );
  }
}
