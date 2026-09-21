import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/free_media_upload_service.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/messaging_repository.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  MessagingRepositoryImpl({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  @override
  String getChatId(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return '${list[0]}_${list[1]}';
  }

  @override
  Stream<List<ConversationEntity>> getUserConversationsStream(String currentUserId) {
    return _firestore
        .collection(AppConstants.conversationsCollection)
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final partnerUid = participants.firstWhere(
          (uid) => uid != currentUserId,
          orElse: () => '',
        );
        return ConversationEntity(
          chatId: doc.id,
          participants: participants,
          lastMessage: data['lastMessage'] ?? '',
          lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          partnerUid: partnerUid,
        );
      }).toList();

      docs.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return docs;
    });
  }

  @override
  Stream<List<MessageEntity>> getMessagesStream(String chatId) {
    return _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesSubcollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MessageEntity(
          messageId: doc.id,
          chatId: chatId,
          senderId: data['senderId'] ?? '',
          receiverId: data['receiverId'] ?? '',
          text: data['text'] ?? '',
          mediaUrl: data['mediaUrl'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
        );
      }).toList();
    });
  }

  @override
  Future<MessageEntity> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    File? mediaFile,
  }) async {
    final chatId = getChatId(senderId, receiverId);
    String? mediaUrl;

    if (mediaFile != null) {
      mediaUrl = await FreeMediaUploadService.uploadPhoto(mediaFile);
    }

    final messageId = _uuid.v4();
    final messageData = {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text.trim(),
      'mediaUrl': mediaUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    final chatRef = _firestore.collection(AppConstants.conversationsCollection).doc(chatId);
    final messageRef = chatRef.collection(AppConstants.messagesSubcollection).doc(messageId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(chatRef, {
        'chatId': chatId,
        'participants': [senderId, receiverId],
        'lastMessage': text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(messageRef, messageData);
    });

    return MessageEntity(
      messageId: messageId,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text.trim(),
      mediaUrl: mediaUrl,
      createdAt: DateTime.now(),
    );
  }
}
