from django.urls import path
from . import views

urlpatterns = [
    path('current/', views.get_current_weather, name='current_weather'),
    path('forecast/', views.get_forecast, name='weather_forecast'),
    path('spray-recommendations/', views.get_spray_recommendations, name='spray_recommendations'),
]