from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Post, Comment, Like, Reaction, Reply, ReplyLike
from .serializers import PostSerializer, CommentSerializer, ReplySerializer, CommentLikeSerializer
from django.shortcuts import get_object_or_404
from rest_framework.permissions import IsAuthenticated



class PostListCreateView(generics.ListCreateAPIView):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    
    def get_queryset(self):
        return Post.objects.all().order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class PostDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    
    def perform_update(self, serializer):
        post = self.get_object()
        if post.user == self.request.user:
            serializer.save()
        else:
            return Response({"detail": "You do not have permission to edit this post."}, 
                            status=status.HTTP_403_FORBIDDEN)
    
    def perform_destroy(self, instance):
        if instance.user == self.request.user:
            instance.delete()
        else:
            return Response({"detail": "You do not have permission to delete this post."}, 
                            status=status.HTTP_403_FORBIDDEN)

class PostLikeView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, pk):
        try:
            post = get_object_or_404(Post, pk=pk)
            user = request.user
            
            # Check if the user has already liked this post
            like, created = Like.objects.get_or_create(user=user, post=post)
            
            # If the like already existed and was created by this user, delete it (unlike)
            if not created and like.user == user:
                like.delete()
                return Response({"detail": "Post unliked successfully."}, status=status.HTTP_200_OK)
            
            # If the like already existed but was created by another user, don't allow unlike
            if not created and like.user != user:
                return Response(
                    {'detail': 'You cannot unlike other users\' likes'}, 
                    status=status.HTTP_403_FORBIDDEN
                )
            
            return Response({"detail": "Post liked successfully."}, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response(
                {'detail': f'An error occurred: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class CommentListCreateView(generics.ListCreateAPIView):
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    
    def get_queryset(self):
        post_id = self.kwargs.get('post_id')
        return Comment.objects.filter(post_id=post_id, parent=None).order_by('-created_at')
    
    def perform_create(self, serializer):
        post_id = self.kwargs.get('post_id')
        post = get_object_or_404(Post, pk=post_id)
        serializer.save(user=self.request.user, post=post)

class CommentDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Comment.objects.all()
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    
    def perform_update(self, serializer):
        comment = self.get_object()
        if comment.user == self.request.user:
            serializer.save()
        else:
            return Response({"detail": "You do not have permission to edit this comment."}, 
                            status=status.HTTP_403_FORBIDDEN)
    
    def perform_destroy(self, instance):
        if instance.user == self.request.user:
            instance.delete()
        else:
            return Response({"detail": "You do not have permission to delete this comment."}, 
                            status=status.HTTP_403_FORBIDDEN)

class CommentLikeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, comment_id):
        try:
            comment = Comment.objects.get(id=comment_id)
            user = request.user
            
            # Check if the user has already liked this comment
            try:
                like = Like.objects.get(user=user, comment=comment)
                # If the like exists and was created by this user, delete it (unlike)
                if like.user == user:
                    like.delete()
                    return Response({'liked': False}, status=status.HTTP_200_OK)
            except Like.DoesNotExist:
                # Create a new like
                Like.objects.create(user=user, comment=comment)
                return Response({'liked': True}, status=status.HTTP_201_CREATED)
            
        except Comment.DoesNotExist:
            return Response(
                {'detail': 'Comment not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'detail': f'An error occurred: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ReplyCreateView(generics.CreateAPIView):
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def perform_create(self, serializer):
        comment_id = self.kwargs.get('comment_id')
        parent_comment = get_object_or_404(Comment, pk=comment_id)
        post = parent_comment.post
        serializer.save(user=self.request.user, post=post, parent=parent_comment)

class ReplyLikeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, reply_id):
        try:
            reply = Reply.objects.get(id=reply_id)
            user = request.user
            
            # Check if the user has already liked this reply
            try:
                like = ReplyLike.objects.get(user=user, reply=reply)
                # If the like exists and was created by this user, delete it (unlike)
                if like.user == user:
                    like.delete()
                    return Response({'liked': False}, status=status.HTTP_200_OK)
            except ReplyLike.DoesNotExist:
                # Create a new like
                ReplyLike.objects.create(user=user, reply=reply)
                return Response({'liked': True}, status=status.HTTP_201_CREATED)
            
        except Reply.DoesNotExist:
            return Response(
                {'detail': 'Reply not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'detail': f'An error occurred: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )