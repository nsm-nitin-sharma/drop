import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String handle;
  final String displayName;
  final String bio;
  final String? photoUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime createdAt;
  final bool isVerified;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.handle,
    required this.displayName,
    required this.bio,
    this.photoUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    required this.createdAt,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [
        uid,
        email,
        handle,
        displayName,
        bio,
        photoUrl,
        followersCount,
        followingCount,
        postsCount,
        createdAt,
        isVerified,
      ];
}
