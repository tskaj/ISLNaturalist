import 'comment.dart';

class Post {
  final int id;
  final String username;
  final String caption;
  final String? imageUrl;
  final String createdAt;
  final int likeCount;
  final bool isLiked;
  final List<Comment> comments;

  Post({
    required this.id,
    required this.username,
    required this.caption,
    this.imageUrl,
    required this.createdAt,
    required this.likeCount,
    required this.isLiked,
    required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<Comment> comments = [];
    if (json['comments'] != null) {
      comments = List<Comment>.from(
        json['comments'].map((comment) => Comment.fromJson(comment)),
      );
    }

    // Make sure we're extracting the username correctly
    String username = '';
    if (json['user'] != null) {
      if (json['user'] is Map) {
        username = json['user']['username'] ?? '';
      } else if (json['user'] is String) {
        username = json['user'];
      }
    }

    return Post(
      id: json['id'],
      username: username,
      caption: json['caption'],
      imageUrl: json['image'],
      createdAt: json['created_at'],
      likeCount: json['like_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      comments: comments,
    );
  }
}