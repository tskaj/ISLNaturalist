import 'package:flutter/material.dart';
import '../models/comment.dart';

class CommentWidget extends StatelessWidget {
  final Comment comment;
  final Function(String) onReply;

  const CommentWidget({
    Key? key,
    required this.comment,
    required this.onReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(comment.username.substring(0, 1).toUpperCase()),
              ),
              const SizedBox(width: 8),
              Text(
                comment.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0, top: 4.0),
            child: Text(comment.content),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0, top: 4.0),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => onReply(comment.id.toString()),
                  child: const Text('Reply', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 16),
                Text(
                  comment.createdAt,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Display replies if any
          if (comment.replies != null && comment.replies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: Column(
                children: comment.replies!
                    .map((reply) => CommentWidget(
                          comment: reply,
                          onReply: onReply,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}