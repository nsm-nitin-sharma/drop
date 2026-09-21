import 'dart:io';
import '../../../auth/domain/entities/user_entity.dart';

abstract class ProfileRepository {
  Future<UserEntity> getUserProfile(String uid);
  Stream<UserEntity> streamUserProfile(String uid);
  Future<UserEntity> updateUserProfile({
    required String uid,
    String? displayName,
    String? bio,
    File? avatarFile,
  });
}
