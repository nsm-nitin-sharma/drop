import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { message, follow, unknown }

class NotificationModel {
  final String id;
  final String recipientId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    NotificationType parsedType;
    final typeStr = data['type'] as String? ?? '';
    switch (typeStr) {
      case 'message':
        parsedType = NotificationType.message;
        break;
      case 'follow':
        parsedType = NotificationType.follow;
        break;
      default:
        parsedType = NotificationType.unknown;
    }

    final timestamp = data['createdAt'];
    DateTime createdDate;
    if (timestamp is Timestamp) {
      createdDate = timestamp.toDate();
    } else if (timestamp is String) {
      createdDate = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      createdDate = DateTime.now();
    }

    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Someone',
      senderAvatar: data['senderAvatar'] as String?,
      type: parsedType,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: createdDate,
      read: data['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': type.name,
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'read': read,
    };
  }
}
