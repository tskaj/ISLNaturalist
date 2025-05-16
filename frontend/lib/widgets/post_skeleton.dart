import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info skeleton
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar skeleton
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User info skeleton
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 10,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Caption skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                width: double.infinity,
                height: 16,
                color: Colors.white,
              ),
            ),
            
            // Image skeleton
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.white,
            ),
            
            // Interaction buttons skeleton
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    width: 60,
                    height: 24,
                    color: Colors.white,
                  ),
                  Container(
                    width: 60,
                    height: 24,
                    color: Colors.white,
                  ),
                  Container(
                    width: 60,
                    height: 24,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            
            // Comments skeleton
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A list skeleton to show multiple post skeletons while loading
class PostListSkeleton extends StatelessWidget {
  final int count;
  
  const PostListSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (context, index) => const PostSkeleton(),
    );
  }
}
