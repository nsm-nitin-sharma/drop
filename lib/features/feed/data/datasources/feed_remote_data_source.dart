import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/post_entity.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';

abstract class FeedRemoteDataSource {
  Stream<List<PostModel>> getFeedPostsStream(String currentUserId);
  Stream<List<PostModel>> getUserPostsStream(String targetUserId, String currentUserId);
  Future<PostModel> createPost({
    required String authorId,
    required String authorHandle,
    String? authorPhotoUrl,
    required String caption,
    required List<File> mediaFiles,
    required MediaType mediaType,
  });
  Future<bool> toggleLikePost(String postId, String currentUserId);
  Stream<List<CommentModel>> getCommentsStream(String postId);
  Future<CommentModel> addComment({
    required String postId,
    required String authorId,
    required String authorHandle,
    String? authorPhotoUrl,
    required String text,
  });
}

class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid;

  FeedRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _uuid = const Uuid();

  @override
  Stream<List<PostModel>> getFeedPostsStream(String currentUserId) {
    return _firestore
        .collection(AppConstants.postsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<PostModel> posts = [];
      for (final doc in snapshot.docs) {
        final isLiked = await _checkIfLiked(doc.id, currentUserId);
        posts.add(PostModel.fromFirestore(doc, isLikedByCurrentUser: isLiked));
      }
      return posts;
    });
  }

  @override
  Stream<List<PostModel>> getUserPostsStream(String targetUserId, String currentUserId) {
    return _firestore
        .collection(AppConstants.postsCollection)
        .where('authorId', isEqualTo: targetUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<PostModel> posts = [];
      for (final doc in snapshot.docs) {
        final isLiked = await _checkIfLiked(doc.id, currentUserId);
        posts.add(PostModel.fromFirestore(doc, isLikedByCurrentUser: isLiked));
      }
      return posts;
    });
  }

  Future<bool> _checkIfLiked(String postId, String userId) async {
    if (userId.isEmpty) return false;
    final docId = '${postId}_$userId';
    final snap = await _firestore.collection(AppConstants.likesCollection).doc(docId).get();
    return snap.exists;
  }

  @override
  Future<PostModel> createPost({
    required String authorId,
    required String authorHandle,
    String? authorPhotoUrl,
    required String caption,
    required List<File> mediaFiles,
    required MediaType mediaType,
  }) async {
    try {
      final List<String> mediaUrls = [];

      // Upload media files to Firebase Storage
      for (final file in mediaFiles) {
        final ext = file.path.split('.').last;
        final fileId = _uuid.v4();
        final ref = _storage
            .ref()
            .child('posts')
            .child(authorId)
            .child('$fileId.$ext');

        final uploadTask = await ref.putFile(file);
        final url = await uploadTask.ref.getDownloadURL();
        mediaUrls.add(url);
      }

      final postId = _uuid.v4();
      final postModel = PostModel(
        postId: postId,
        authorId: authorId,
        authorHandle: authorHandle,
        authorPhotoUrl: authorPhotoUrl,
        caption: caption.trim(),
        mediaUrls: mediaUrls,
        mediaType: mediaType,
        createdAt: DateTime.now(),
      );

      // Save to Firestore and increment user post count in transaction
      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection(AppConstants.postsCollection).doc(postId);
        transaction.set(postRef, postModel.toFirestore());

        final userRef = _firestore.collection(AppConstants.usersCollection).doc(authorId);
        transaction.update(userRef, {
          'postsCount': FieldValue.increment(1),
        });
      });

      return postModel;
    } catch (e) {
      throw const ServerFailure('Failed to upload post. Please try again.');
    }
  }

  @override
  Future<bool> toggleLikePost(String postId, String currentUserId) async {
    final likeDocId = '${postId}_$currentUserId';
    final likeRef = _firestore.collection(AppConstants.likesCollection).doc(likeDocId);
    final postRef = _firestore.collection(AppConstants.postsCollection).doc(postId);

    bool nowLiked = false;

    await _firestore.runTransaction((transaction) async {
      final likeSnap = await transaction.get(likeRef);
      if (likeSnap.exists) {
        // Unlike
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'likesCount': FieldValue.increment(-1),
        });
        nowLiked = false;
      } else {
        // Like
        transaction.set(likeRef, {
          'postId': postId,
          'userId': currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {
          'likesCount': FieldValue.increment(1),
        });
        nowLiked = true;
      }
    });

    return nowLiked;
  }

  @override
  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _firestore
        .collection(AppConstants.commentsCollection)
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
  }

  @override
  Future<CommentModel> addComment({
    required String postId,
    required String authorId,
    required String authorHandle,
    String? authorPhotoUrl,
    required String text,
  }) async {
    final commentId = _uuid.v4();
    final commentModel = CommentModel(
      commentId: commentId,
      postId: postId,
      authorId: authorId,
      authorHandle: authorHandle,
      authorPhotoUrl: authorPhotoUrl,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    await _firestore.runTransaction((transaction) async {
      final commentRef = _firestore.collection(AppConstants.commentsCollection).doc(commentId);
      transaction.set(commentRef, commentModel.toFirestore());

      final postRef = _firestore.collection(AppConstants.postsCollection).doc(postId);
      transaction.update(postRef, {
        'commentsCount': FieldValue.increment(1),
      });
    });

    return commentModel;
  }
}
