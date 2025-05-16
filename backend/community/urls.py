from django.urls import path
from .views import (
    PostListCreateView,
    PostDetailView,
    PostLikeView,
    CommentListCreateView,
    CommentDetailView,
    CommentLikeView,
    ReplyLikeView,
    ReplyCreateView
)

urlpatterns = [
    path('posts/', PostListCreateView.as_view(), name='post-list-create'),
    path('posts/<int:pk>/', PostDetailView.as_view(), name='post-detail'),
    path('posts/<int:pk>/like/', PostLikeView.as_view(), name='post-like'),
    path('posts/<int:post_id>/comments/', CommentListCreateView.as_view(), name='comment-list-create'),
    path('comments/<int:pk>/', CommentDetailView.as_view(), name='comment-detail'),
    path('comments/<int:comment_id>/like/', CommentLikeView.as_view(), name='comment-like'),
    path('comments/<int:comment_id>/reply/', ReplyCreateView.as_view(), name='reply-create'),
    # This is the correct URL pattern for reply likes
    path('replies/<int:reply_id>/like/', ReplyLikeView.as_view(), name='reply-like'),
]