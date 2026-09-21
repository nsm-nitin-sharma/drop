import 'package:equatable/equatable.dart';

class CommentEntity extends Equatable {
  final String commentId;
  final String postId;
  final String authorId;
  final String authorHandle;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;

  const CommentEntity({
    required this.commentId,
    required this.postId,
    required this.authorId,
    required this.authorHandle,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        commentId,
        postId,
        authorId,
        authorHandle,
        authorPhotoUrl,
        text,
        createdAt,
      ];
}
