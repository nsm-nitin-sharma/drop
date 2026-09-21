import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/monochrome_avatar.dart';
import '../../../../core/widgets/smart_image.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/messaging_repository.dart';

class ChatPage extends StatefulWidget {
  final UserEntity currentUser;
  final UserEntity targetUser;
  final MessagingRepository messagingRepository;

  const ChatPage({
    super.key,
    required this.currentUser,
    required this.targetUser,
    required this.messagingRepository,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _imagePicker = ImagePicker();
  late String _chatId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _chatId = widget.messagingRepository.getChatId(
      widget.currentUser.uid,
      widget.targetUser.uid,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({File? mediaFile}) async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && mediaFile == null) || _isSending) return;

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    try {
      await widget.messagingRepository.sendMessage(
        senderId: widget.currentUser.uid,
        receiverId: widget.targetUser.uid,
        text: text,
        mediaFile: mediaFile,
      );

      // Trigger Push & In-App Notification
      NotificationService.instance.sendNotification(
        recipientId: widget.targetUser.uid,
        senderId: widget.currentUser.uid,
        senderName: widget.currentUser.displayName,
        senderAvatar: widget.currentUser.photoUrl,
        type: 'message',
        title: widget.currentUser.displayName,
        body: text.isNotEmpty ? text : 'Sent an attachment',
        dataPayload: {
          'chatId': _chatId,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickAndAttachImage() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      await _sendMessage(mediaFile: File(picked.path));
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
        title: Row(
          children: [
            MonochromeAvatar(
              photoUrl: widget.targetUser.photoUrl,
              radius: 16,
              fallbackInitial: widget.targetUser.handle,
            ),
            const SizedBox(width: 10),
            Text(
              '@${widget.targetUser.handle}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Real-time Chat Messages List
          Expanded(
            child: StreamBuilder<List<MessageEntity>>(
              stream: widget.messagingRepository.getMessagesStream(_chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello to @${widget.targetUser.handle}!',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.currentUser.uid;
                    final hasMedia = message.mediaUrl != null && message.mediaUrl!.isNotEmpty;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.symmetric(
                          horizontal: hasMedia ? 6 : 14,
                          vertical: hasMedia ? 6 : 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? (isDark ? AppColors.white : AppColors.black)
                              : surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isMe ? null : Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasMedia)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SmartImage(
                                  imageUrl: message.mediaUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            if (message.text.isNotEmpty) ...[
                              if (hasMedia) const SizedBox(height: 6),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: hasMedia ? 8 : 0),
                                child: Text(
                                  message.text,
                                  style: TextStyle(
                                    color: isMe
                                        ? (isDark ? AppColors.black : AppColors.white)
                                        : primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image_outlined, color: textSecondary),
                    onPressed: _isSending ? null : _pickAndAttachImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: primaryColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Message @${widget.targetUser.handle}...',
                        hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.send_rounded, color: primaryColor),
                          onPressed: () => _sendMessage(),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
