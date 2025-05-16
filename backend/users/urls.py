from django.urls import path
from .views import (
    RegisterView, LoginView, DeleteUserView, predict_image, 
    predict_image_anonymous, get_disease_info, UserProfileView,
    CommunityPostListCreateView, CommunityPostDetailView, 
    PostLikeView, CommentListCreateView
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('delete/', DeleteUserView.as_view(), name='delete_user'),
    path('predict/', predict_image, name='predict_image'),
    path('predict-anonymous/', predict_image_anonymous, name='predict_image_anonymous'),
    path('disease-info/<str:disease_name>/', get_disease_info, name='get_disease_info'),
    path('profile/', UserProfileView.as_view(), name='user_profile'),
    path('community/posts/', CommunityPostListCreateView.as_view(), name='community_posts'),
    path('community/posts/<int:pk>/', CommunityPostDetailView.as_view(), name='post_detail'),
    path('community/posts/<int:pk>/like/', PostLikeView.as_view(), name='post_like'),
    path('community/posts/<int:post_id>/comments/', CommentListCreateView.as_view(), name='post_comments'),
    path('community/posts/<int:pk>/react/', PostLikeView.as_view(), name='post-reaction'),
    # Add this URL pattern
    path('community/posts/<int:post_id>/', CommunityPostDetailView.as_view(), name='delete-post'),
]
