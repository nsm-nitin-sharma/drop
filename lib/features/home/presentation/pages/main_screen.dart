import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;

    final List<Widget> pages = [
      // 0: Feed Screen
      _buildPlaceholderTab(
        context,
        title: 'DROP FEED',
        subtitle: 'Real-time photos & video feed will appear here.',
        icon: Icons.home_filled,
      ),

      // 1: Search Screen
      _buildPlaceholderTab(
        context,
        title: 'SEARCH',
        subtitle: 'Search users by @handle (e.g. @nitin_sharma)',
        icon: Icons.search,
      ),

      // 2: Post Create Screen
      _buildPlaceholderTab(
        context,
        title: 'NEW POST',
        subtitle: 'Upload photo or video to Drop.',
        icon: Icons.add_box_outlined,
      ),

      // 3: Reels Screen
      _buildPlaceholderTab(
        context,
        title: 'REELS',
        subtitle: 'Instagram Reels-style auto-play video player.',
        icon: Icons.movie_outlined,
      ),

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

  Widget _buildPlaceholderTab(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, dynamic currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
                  '@${currentUser?.handle ?? 'user'}',
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
                CircleAvatar(
                  radius: 36,
                  backgroundColor: surfaceColor,
                  child: Text(
                    currentUser?.displayName.isNotEmpty == true
                        ? currentUser!.displayName[0].toUpperCase()
                        : 'D',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(context, '${currentUser?.postsCount ?? 0}', 'Posts'),
                      _buildStatColumn(context, '${currentUser?.followersCount ?? 0}', 'Followers'),
                      _buildStatColumn(context, '${currentUser?.followingCount ?? 0}', 'Following'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name & Bio
            Text(
              currentUser?.displayName ?? 'Drop User',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentUser?.bio.isNotEmpty == true
                  ? currentUser!.bio
                  : 'Welcome to Drop.',
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Actions
            OutlinedButton(
              onPressed: () {
                context.read<AuthBloc>().add(AuthSignOutRequested());
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Log Out',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
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
