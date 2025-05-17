from django.urls import path
from . import views

urlpatterns = [
    path('posts/', views.post_list_create, name='post_list_create'),
    path('posts/<int:pk>/', views.post_detail, name='post_detail'),
    path('posts/<int:pk>/like/', views.like_post, name='like_post'),
    path('posts/<int:pk>/comments/', views.add_comment, name='add_comment'),
]