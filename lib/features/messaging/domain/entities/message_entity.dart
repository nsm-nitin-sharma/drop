import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String messageId;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final String? mediaUrl;
  final DateTime createdAt;
  final bool isRead;

  const MessageEntity({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.mediaUrl,
    required this.createdAt,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [
        messageId,
        chatId,
        senderId,
        receiverId,
        text,
        mediaUrl,
        createdAt,
        isRead,
      ];
}
