import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  const PostModel({
    required super.postId,
    required super.authorId,
    required super.authorHandle,
    super.authorPhotoUrl,
    required super.caption,
    required super.mediaUrls,
    required super.mediaType,
    super.likesCount,
    super.commentsCount,
    required super.createdAt,
    super.isLikedByCurrentUser,
  });

  factory PostModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    bool isLikedByCurrentUser = false,
  }) {
    final data = doc.data() ?? {};
    final mediaTypeStr = data['mediaType'] as String? ?? 'photo';
    return PostModel(
      postId: doc.id,
      authorId: data['authorId'] ?? '',
      authorHandle: data['authorHandle'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      caption: data['caption'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      mediaType: mediaTypeStr == 'video' ? MediaType.video : MediaType.photo,
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLikedByCurrentUser: isLikedByCurrentUser,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorHandle': authorHandle,
      'authorPhotoUrl': authorPhotoUrl,
      'caption': caption,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType == MediaType.video ? 'video' : 'photo',
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
