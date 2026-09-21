import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/monochrome_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/messaging_repository.dart';
import 'chat_page.dart';

class ConversationsPage extends StatelessWidget {
  final UserEntity currentUser;
  final MessagingRepository messagingRepository;
  final ProfileRepository profileRepository;

  const ConversationsPage({
    super.key,
    required this.currentUser,
    required this.messagingRepository,
    required this.profileRepository,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      body: StreamBuilder<List<ConversationEntity>>(
        stream: messagingRepository.getUserConversationsStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 56, color: textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search for a handle to start a conversation.',
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final conv = conversations[index];

              return StreamBuilder<UserEntity>(
                stream: profileRepository.streamUserProfile(conv.partnerUid),
                builder: (context, userSnap) {
                  final partnerUser = userSnap.data;
                  final partnerHandle = partnerUser?.handle ?? 'user';
                  final partnerPhoto = partnerUser?.photoUrl;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: MonochromeAvatar(
                      photoUrl: partnerPhoto,
                      radius: 24,
                      fallbackInitial: partnerHandle,
                    ),
                    title: Text(
                      '@$partnerHandle',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: primaryColor,
                      ),
                    ),
                    subtitle: Text(
                      conv.lastMessage.isNotEmpty ? conv.lastMessage : 'Media message',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                    onTap: () {
                      if (partnerUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              currentUser: currentUser,
                              targetUser: partnerUser,
                              messagingRepository: messagingRepository,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
