class Comment {
  final int id;
  final String username;
  final String content;
  final String createdAt;
  final int? parentId;
  final List<Comment>? replies;

  Comment({
    required this.id,
    required this.username,
    required this.content,
    required this.createdAt,
    this.parentId,
    this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    List<Comment> replies = [];
    if (json['replies'] != null) {
      replies = List<Comment>.from(
        json['replies'].map((reply) => Comment.fromJson(reply)),
      );
    }

    return Comment(
      id: json['id'],
      username: json['user']['username'],
      content: json['content'],
      createdAt: json['created_at'],
      parentId: json['parent'],
      replies: replies,
    );
  }
}