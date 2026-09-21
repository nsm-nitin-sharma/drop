import 'dart:io';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_data_source.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource _remoteDataSource;

  FeedRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<PostEntity>> getFeedPostsStream({required String currentUserId}) {
    return _remoteDataSource.getFeedPostsStream(currentUserId);
  }

  @override
  Stream<List<PostEntity>> getUserPostsStream({
    required String targetUserId,
    required String currentUserId,
  }) {
    return _remoteDataSource.getUserPostsStream(targetUserId, currentUserId);
  }

  @override
  Future<PostEntity> createPost({
    required String authorId,
    required String authorHandle,
    String? authorPhotoUrl,
    required String caption,
    required List<File> mediaFiles,
    required MediaType mediaType,
  }) {
    return _remoteDataSource.createPost(
      authorId: authorId,
      authorHandle: authorHandle,
      authorPhotoUrl: authorPhotoUrl,
      caption: caption,
      mediaFiles: mediaFiles,
      mediaType: mediaType,
    );
  }

  @override
  Future<bool> toggleLikePost({
    required String postId,
    required String currentUserId,
  }) {
    return _remoteDataSource.toggleLikePost(postId, currentUserId);
  }

  @override
  Stream<List<CommentEntity>> getCommentsStream(String postId) {
    return _remoteDataSource.getCommentsStream(postId);
  }

  @override
  Future<CommentEntity> addComment({
    required String postId,
    required String authorId,
    required String authorHandle,
    String? authorPhotoUrl,
    required String text,
  }) {
    return _remoteDataSource.addComment(
      postId: postId,
      authorId: authorId,
      authorHandle: authorHandle,
      authorPhotoUrl: authorPhotoUrl,
      text: text,
    );
  }
}
