from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include
from users.views import (
    RegisterView, 
    LoginView, 
    DeleteUserView, 
    predict_image, 
    predict_image_anonymous,
    get_disease_info,
    UserProfileView
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/community/', include('community.urls')),
    path('api/disease/', include('disease_detection.urls')),
    path('api/weather/', include('weather.urls')),
    
    # Authentication endpoints
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('delete-account/', DeleteUserView.as_view(), name='delete-account'),
    
    # Prediction endpoints
    path('predict/', predict_image, name='predict'),
    path('predict-anonymous/', predict_image_anonymous, name='predict-anonymous'),
    
    # Disease info endpoint
    path('disease-info/<str:disease_name>/', get_disease_info, name='disease-info'),
    
    # User profile endpoint
    path('profile/', UserProfileView.as_view(), name='user-profile'),

    # Insect detection
    path('api/insects/', include('insect_detection.urls')),
    
    # Bird detection
    path('api/birds/', include('bird_detection.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
