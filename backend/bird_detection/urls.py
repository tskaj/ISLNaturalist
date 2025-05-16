from django.urls import path
from .views import BirdDetectionView, AnonymousBirdDetectionView

urlpatterns = [
    path('detect/', BirdDetectionView.as_view(), name='bird_detection'),
    path('detect-anonymous/', AnonymousBirdDetectionView.as_view(), name='anonymous_bird_detection'),
]