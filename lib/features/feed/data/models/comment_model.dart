import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/comment_entity.dart';

class CommentModel extends CommentEntity {
  const CommentModel({
    required super.commentId,
    required super.postId,
    required super.authorId,
    required super.authorHandle,
    super.authorPhotoUrl,
    required super.text,
    required super.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommentModel(
      commentId: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorHandle: data['authorHandle'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'commentId': commentId,
      'postId': postId,
      'authorId': authorId,
      'authorHandle': authorHandle,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
