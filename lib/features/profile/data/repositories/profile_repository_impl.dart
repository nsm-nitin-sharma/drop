import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/free_media_upload_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore;

  ProfileRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserEntity> getUserProfile(String uid) async {
    final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) {
      throw const ServerFailure('User profile not found.');
    }
    return UserModel.fromFirestore(doc);
  }

  @override
  Stream<UserEntity> streamUserProfile(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => UserModel.fromFirestore(doc));
  }

  @override
  Future<UserEntity> updateUserProfile({
    required String uid,
    String? displayName,
    String? bio,
    File? avatarFile,
  }) async {
    String? photoUrl;

    if (avatarFile != null) {
      photoUrl = await FreeMediaUploadService.uploadPhoto(avatarFile);
    }

    final Map<String, dynamic> updateData = {};
    if (displayName != null) updateData['displayName'] = displayName.trim();
    if (bio != null) updateData['bio'] = bio.trim();
    if (photoUrl != null) updateData['photoUrl'] = photoUrl;

    if (updateData.isNotEmpty) {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(updateData);
    }

    return await getUserProfile(uid);
  }
}
