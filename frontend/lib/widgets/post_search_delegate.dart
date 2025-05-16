import 'package:flutter/material.dart';
import '../screens/community_screen.dart';

class PostSearchDelegate extends SearchDelegate<dynamic> {
  final List<dynamic> posts;

  PostSearchDelegate(this.posts);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('Enter a search term to find posts'),
      );
    }

    final filteredPosts = posts.where((post) {
      final caption = post['caption']?.toString().toLowerCase() ?? '';
      final username = post['user']?.toString().toLowerCase() ?? '';
      final searchLower = query.toLowerCase();
      
      return caption.contains(searchLower) || username.contains(searchLower);
    }).toList();

    if (filteredPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No posts found for "$query"'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        final post = filteredPosts[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(post['user'].toString()[0].toUpperCase()),
          ),
          title: Text(post['user'].toString()),
          subtitle: Text(
            post['caption'].toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            close(context, post);
          },
        );
      },
    );
  }
}