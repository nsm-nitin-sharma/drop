import 'package:equatable/equatable.dart';

enum MediaType { photo, video }

class PostEntity extends Equatable {
  final String postId;
  final String authorId;
  final String authorHandle;
  final String? authorPhotoUrl;
  final String caption;
  final List<String> mediaUrls;
  final MediaType mediaType;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final bool isLikedByCurrentUser;

  const PostEntity({
    required this.postId,
    required this.authorId,
    required this.authorHandle,
    this.authorPhotoUrl,
    required this.caption,
    required this.mediaUrls,
    required this.mediaType,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.isLikedByCurrentUser = false,
  });

  PostEntity copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLikedByCurrentUser,
  }) {
    return PostEntity(
      postId: postId,
      authorId: authorId,
      authorHandle: authorHandle,
      authorPhotoUrl: authorPhotoUrl,
      caption: caption,
      mediaUrls: mediaUrls,
      mediaType: mediaType,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }

  @override
  List<Object?> get props => [
        postId,
        authorId,
        authorHandle,
        authorPhotoUrl,
        caption,
        mediaUrls,
        mediaType,
        likesCount,
        commentsCount,
        createdAt,
        isLikedByCurrentUser,
      ];
}
