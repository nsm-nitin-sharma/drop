import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final FirebaseFirestore _firestore;

  SearchRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<UserEntity>> searchUsersByHandle(String query) async {
    final cleanQuery = query.trim().toLowerCase().replaceAll('@', '');
    if (cleanQuery.isEmpty) return [];

    try {
      final snap = await _firestore
          .collection(AppConstants.usersCollection)
          .where('handle', isGreaterThanOrEqualTo: cleanQuery)
          .where('handle', isLessThanOrEqualTo: '$cleanQuery\uf8ff')
          .limit(20)
          .get();

      return snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (_) {
      return [];
    }
  }
}
