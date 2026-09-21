import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.handle,
    required super.displayName,
    required super.bio,
    super.photoUrl,
    super.followersCount,
    super.followingCount,
    super.postsCount,
    required super.createdAt,
    super.isVerified,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      handle: data['handle'] ?? '',
      displayName: data['displayName'] ?? '',
      bio: data['bio'] ?? '',
      photoUrl: data['photoUrl'],
      followersCount: (data['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
      postsCount: (data['postsCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'handle': handle.toLowerCase(),
      'displayName': displayName,
      'bio': bio,
      'photoUrl': photoUrl,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
    };
  }
}
