import 'dart:io';
import '../entities/comment_entity.dart';
import '../entities/post_entity.dart';

abstract class FeedRepository {
  Stream<List<PostEntity>> getFeedPostsStream({required String currentUserId});
  Stream<List<PostEntity>> getUserPostsStream({
    required String targetUserId,
    required String currentUserId,
  });

  Future<PostEntity> createPost({
    required String authorId,
    required String authorHandle,
    String? authorPhotoUrl,
    required String caption,
    required List<File> mediaFiles,
    required MediaType mediaType,
  });

  Future<bool> toggleLikePost({
    required String postId,
    required String currentUserId,
  });

  Stream<List<CommentEntity>> getCommentsStream(String postId);

  Future<CommentEntity> addComment({
    required String postId,
    required String authorId,
    required String authorHandle,
    String? authorPhotoUrl,
    required String text,
  });

  Future<void> deletePost({
    required String postId,
    required String authorId,
  });
}
