import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/social_graph_repository.dart';

class SocialGraphRepositoryImpl implements SocialGraphRepository {
  final FirebaseFirestore _firestore;

  SocialGraphRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<bool> isFollowingStream({
    required String currentUid,
    required String targetUid,
  }) {
    if (currentUid.isEmpty || targetUid.isEmpty) {
      return Stream.value(false);
    }
    final docRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUid)
        .collection(AppConstants.followingSubcollection)
        .doc(targetUid);

    return docRef.snapshots().map((snap) => snap.exists);
  }

  @override
  Future<void> followUser({
    required String currentUid,
    required String targetUid,
  }) async {
    if (currentUid == targetUid) return;

    final followingRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUid)
        .collection(AppConstants.followingSubcollection)
        .doc(targetUid);

    final followerRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(targetUid)
        .collection(AppConstants.followersSubcollection)
        .doc(currentUid);

    final currentUserRef = _firestore.collection(AppConstants.usersCollection).doc(currentUid);
    final targetUserRef = _firestore.collection(AppConstants.usersCollection).doc(targetUid);

    await _firestore.runTransaction((transaction) async {
      transaction.set(followingRef, {'uid': targetUid, 'createdAt': FieldValue.serverTimestamp()});
      transaction.set(followerRef, {'uid': currentUid, 'createdAt': FieldValue.serverTimestamp()});

      transaction.update(currentUserRef, {'followingCount': FieldValue.increment(1)});
      transaction.update(targetUserRef, {'followersCount': FieldValue.increment(1)});
    });
  }

  @override
  Future<void> unfollowUser({
    required String currentUid,
    required String targetUid,
  }) async {
    if (currentUid == targetUid) return;

    final followingRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUid)
        .collection(AppConstants.followingSubcollection)
        .doc(targetUid);

    final followerRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(targetUid)
        .collection(AppConstants.followersSubcollection)
        .doc(currentUid);

    final currentUserRef = _firestore.collection(AppConstants.usersCollection).doc(currentUid);
    final targetUserRef = _firestore.collection(AppConstants.usersCollection).doc(targetUid);

    await _firestore.runTransaction((transaction) async {
      transaction.delete(followingRef);
      transaction.delete(followerRef);

      transaction.update(currentUserRef, {'followingCount': FieldValue.increment(-1)});
      transaction.update(targetUserRef, {'followersCount': FieldValue.increment(-1)});
    });
  }

  @override
  Future<List<UserEntity>> getFollowers(String uid) async {
    final snap = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.followersSubcollection)
        .get();

    final List<UserEntity> users = [];
    for (final doc in snap.docs) {
      final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(doc.id).get();
      if (userDoc.exists) {
        users.add(UserModel.fromFirestore(userDoc));
      }
    }
    return users;
  }

  @override
  Future<List<UserEntity>> getFollowing(String uid) async {
    final snap = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.followingSubcollection)
        .get();

    final List<UserEntity> users = [];
    for (final doc in snap.docs) {
      final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(doc.id).get();
      if (userDoc.exists) {
        users.add(UserModel.fromFirestore(userDoc));
      }
    }
    return users;
  }
}
