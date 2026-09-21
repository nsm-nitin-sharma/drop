import '../../../auth/domain/entities/user_entity.dart';

abstract class SocialGraphRepository {
  Stream<bool> isFollowingStream({
    required String currentUid,
    required String targetUid,
  });

  Future<void> followUser({
    required String currentUid,
    required String targetUid,
  });

  Future<void> unfollowUser({
    required String currentUid,
    required String targetUid,
  });

  Future<List<UserEntity>> getFollowers(String uid);
  Future<List<UserEntity>> getFollowing(String uid);
}
