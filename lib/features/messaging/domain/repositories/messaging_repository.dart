import 'dart:io';
import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';

abstract class MessagingRepository {
  Stream<List<MessageEntity>> getMessagesStream(String chatId);

  Stream<List<ConversationEntity>> getUserConversationsStream(String currentUserId);

  Future<MessageEntity> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    File? mediaFile,
  });

  String getChatId(String uid1, String uid2);
}

