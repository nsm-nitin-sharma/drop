import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/monochrome_avatar.dart';
import '../../../../core/widgets/monochrome_button.dart';
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

  @override
  void initState() {
    super.initState();
    _feedRepository = FeedRepositoryImpl(FeedRemoteDataSourceImpl());
    _searchRepository = SearchRepositoryImpl();
    _socialGraphRepository = SocialGraphRepositoryImpl();
    _profileRepository = ProfileRepositoryImpl();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final List<Widget> pages = [
      // 0: Feed Screen
      _buildFeedTab(context, currentUser),

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

      // 3: Reels Screen (Vertical Snap Video Feed)
      _buildReelsTab(context, currentUser),

      // 4: Profile Screen
      _buildProfileTab(context, currentUser),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_filled),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              activeIcon: Icon(Icons.add_box),
              label: 'Post',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.movie_outlined),
              activeIcon: Icon(Icons.movie),
              label: 'Reels',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTab(BuildContext context, UserEntity currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DROP',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: 3.0,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<PostEntity>>(
              stream: _feedRepository.getFeedPostsStream(currentUserId: currentUser.uid),
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
                          onPressed: () {
                            setState(() {
                              _selectedIndex = 2;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildPostCard(context, post, currentUser);
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
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final mediaUrl = post.mediaUrls.isNotEmpty ? post.mediaUrls.first : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              ],
            ),
          ),

          // Post Media
          if (mediaUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 1.0,
              child: CachedNetworkImage(
                imageUrl: mediaUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: isDark ? AppColors.darkCard : AppColors.lightCard),
              ),
            ),

          // Post Actions Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                    color: post.isLikedByCurrentUser ? AppColors.heartRed : primaryColor,
                  ),
                  onPressed: () {
                    _feedRepository.toggleLikePost(
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildReelsTab(BuildContext context, UserEntity currentUser) {
    final textSecondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return StreamBuilder<List<PostEntity>>(
      stream: _feedRepository.getFeedPostsStream(currentUserId: currentUser.uid),
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
                _feedRepository.toggleLikePost(
                  postId: post.postId,
                  currentUserId: currentUser.uid,
                );
              },
              onCommentTap: () => _showCommentsSheet(context, post, currentUser),
            );
          },
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
        feedRepository: _feedRepository,
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, UserEntity currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return StreamBuilder<UserEntity>(
      stream: _profileRepository.streamUserProfile(currentUser.uid),
      initialData: currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data ?? currentUser;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
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
                const SizedBox(height: 24),

                // Profile Info Header
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
                  user.bio.isNotEmpty ? user.bio : 'Welcome to Drop.',
                  style: TextStyle(color: textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Edit Profile Button
                MonochromeButton(
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
                        profileRepository: _profileRepository,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Log Out Button
                OutlinedButton(
                  onPressed: () => _showLogoutConfirmationDialog(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 42),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Log Out',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // User Posts Grid
                StreamBuilder<List<PostEntity>>(
                  stream: _feedRepository.getUserPostsStream(
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
