from rest_framework import serializers
from .models import Post, Comment, Like, Reaction, Reply
from django.contrib.auth import get_user_model

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    profile_image = serializers.ImageField(read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'profile_image']

class CommentLikeSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = Like
        fields = ['id', 'user', 'created_at']

class ReplySerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    likes_count = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()

    class Meta:
        model = Reply
        fields = ['id', 'user', 'content', 'created_at', 'likes_count', 'is_liked']
        # Remove 'updated_at' from this list if it's present

    def get_likes_count(self, obj):
        return obj.likes.count()
    
    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Like.objects.filter(comment=obj, user=request.user).exists()
        return False

class CommentSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    replies = serializers.SerializerMethodField()
    likes_count = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    
    class Meta:
        model = Comment
        fields = ['id', 'user', 'content', 'created_at', 'parent', 'replies', 'likes_count', 'is_liked']
    
    def get_replies(self, obj):
        replies = Comment.objects.filter(parent=obj)
        return ReplySerializer(replies, many=True, context=self.context).data
    
    def get_likes_count(self, obj):
        return obj.likes.count()
    
    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Like.objects.filter(comment=obj, user=request.user).exists()
        return False

class PostSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    comments = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    like_count = serializers.SerializerMethodField()
    reactions = serializers.SerializerMethodField()
    comment_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Post
        fields = ['id', 'user', 'caption', 'image', 'created_at', 'comments', 'is_liked', 'like_count', 'reactions', 'comment_count']
    
    def get_comments(self, obj):
        # Only get top-level comments (no parent)
        comments = Comment.objects.filter(post=obj, parent=None).order_by('-created_at')
        return CommentSerializer(comments, many=True, context=self.context).data
    
    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Like.objects.filter(post=obj, user=request.user).exists()
        return False
    
    def get_like_count(self, obj):
        return obj.likes.count()
    
    def get_comment_count(self, obj):
        return Comment.objects.filter(post=obj).count()
    
    def get_reactions(self, obj):
        return ReactionSerializer(obj.reactions.all(), many=True).data

class ReactionSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.username')
    
    class Meta:
        model = Reaction
        fields = ['id', 'user', 'post', 'reaction_type', 'created_at']