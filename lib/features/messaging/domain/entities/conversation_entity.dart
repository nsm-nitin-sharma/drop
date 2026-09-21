import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String partnerUid;

  const ConversationEntity({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.partnerUid,
  });

  @override
  List<Object?> get props => [
        chatId,
        participants,
        lastMessage,
        lastMessageTime,
        partnerUid,
      ];
}
