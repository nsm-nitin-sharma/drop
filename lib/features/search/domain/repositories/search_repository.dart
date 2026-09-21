import '../../../auth/domain/entities/user_entity.dart';

abstract class SearchRepository {
  Future<List<UserEntity>> searchUsersByHandle(String query);
}
