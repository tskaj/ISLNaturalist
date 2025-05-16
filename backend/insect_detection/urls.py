from django.urls import path
from .views import InsectDetectionView, AnonymousInsectDetectionView

urlpatterns = [
    path('detect/', InsectDetectionView.as_view(), name='detect_insect'),
    path('detect-anonymous/', AnonymousInsectDetectionView.as_view(), name='detect_insect_anonymous'),
]