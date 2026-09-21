import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/monochrome_avatar.dart';
import '../../../../core/widgets/monochrome_text_field.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/search_repository.dart';

class SearchPage extends StatefulWidget {
  final SearchRepository searchRepository;
  final Function(UserEntity) onUserSelected;

  const SearchPage({
    super.key,
    required this.searchRepository,
    required this.onUserSelected,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<UserEntity> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final results = await widget.searchRepository.searchUsersByHandle(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: MonochromeTextField(
              controller: _searchController,
              label: 'Search Handle',
              hint: 'Search by @handle (e.g. nitin_sharma)',
              prefixIcon: Icons.search,
              onChanged: _onSearchQueryChanged,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _searchResults.isEmpty && _searchController.text.isNotEmpty
                    ? Center(
                        child: Text(
                          'No users found matching "${_searchController.text}"',
                          style: TextStyle(color: textSecondary, fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return ListTile(
                            leading: MonochromeAvatar(
                              photoUrl: user.photoUrl,
                              radius: 20,
                              fallbackInitial: user.handle,
                            ),
                            title: Text(
                              '@${user.handle}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            subtitle: Text(
                              user.displayName,
                              style: TextStyle(color: textSecondary, fontSize: 13),
                            ),
                            onTap: () => widget.onUserSelected(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
