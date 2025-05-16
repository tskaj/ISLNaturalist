from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import CustomUser, Comment, CommunityPost

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = CustomUser
        fields = ['username', 'email', 'password']

    def create(self, validated_data):
        user = CustomUser.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password']
        )
        return user

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        data['username'] = self.user.username
        data['email'] = self.user.email
        return data

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'bio', 'profile_image']
        read_only_fields = ['id', 'username']

class CommentSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.username')
    user_id = serializers.ReadOnlyField(source='user.id')
    
    class Meta:
        model = Comment
        fields = ['id', 'post', 'user', 'user_id', 'text', 'created_at']
        read_only_fields = ['id', 'user', 'user_id', 'created_at']

class CommunityPostSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.username')
    user_id = serializers.ReadOnlyField(source='user.id')
    comments = CommentSerializer(many=True, read_only=True)
    like_count = serializers.ReadOnlyField()
    is_liked = serializers.SerializerMethodField()
    
    class Meta:
        model = CommunityPost
        fields = ['id', 'user', 'user_id', 'image', 'caption', 'created_at', 'comments', 'like_count', 'is_liked']
        read_only_fields = ['id', 'user', 'user_id', 'created_at', 'like_count']
    
    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes.filter(id=request.user.id).exists()
        return False
