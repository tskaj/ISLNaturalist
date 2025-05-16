from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
import requests
import os
from datetime import datetime, timedelta

# OpenWeather API configuration
OPENWEATHER_API_KEY = os.environ.get('OPENWEATHER_API_KEY', '6268477fd958d098c4fd75f9e8456597')
OPENWEATHER_BASE_URL = 'https://api.openweathermap.org/data/2.5'

@api_view(['GET'])
@permission_classes([AllowAny])
def get_current_weather(request):
    """
    Get current weather data for a location
    Required query parameters: lat, lon
    Optional: units (metric, imperial, standard)
    """
    try:
        # Get parameters from request
        lat = request.GET.get('lat')
        lon = request.GET.get('lon')
        units = request.GET.get('units', 'metric')  # Default to metric
        
        # Validate parameters
        if not lat or not lon:
            return Response(
                {'error': 'Latitude and longitude are required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Check if API key is configured
        if not OPENWEATHER_API_KEY:
            return Response(
                {'error': 'Weather API is not configured'}, 
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )
        
        # Make request to OpenWeather API
        url = f"{OPENWEATHER_BASE_URL}/weather"
        params = {
            'lat': lat,
            'lon': lon,
            'units': units,
            'appid': OPENWEATHER_API_KEY
        }
        
        response = requests.get(url, params=params)
        data = response.json()
        
        if response.status_code != 200:
            return Response(
                {'error': data.get('message', 'Failed to fetch weather data')},
                status=status.HTTP_502_BAD_GATEWAY
            )
        
        # Extract relevant weather information
        weather_data = {
            'temperature': data['main']['temp'],
            'feels_like': data['main']['feels_like'],
            'humidity': data['main']['humidity'],
            'pressure': data['main']['pressure'],
            'wind_speed': data['wind']['speed'],
            'wind_direction': data['wind']['deg'],
            'weather_condition': data['weather'][0]['main'],
            'weather_description': data['weather'][0]['description'],
            'weather_icon': data['weather'][0]['icon'],
            'location_name': data['name'],
            'country': data['sys']['country'],
            'sunrise': data['sys']['sunrise'],
            'sunset': data['sys']['sunset'],
            'timezone': data['timezone'],
            'units': units
        }
        
        return Response(weather_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': f'An error occurred: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([AllowAny])
def get_forecast(request):
    """
    Get 5-day weather forecast for a location
    Required query parameters: lat, lon
    Optional: units (metric, imperial, standard)
    """
    try:
        # Get parameters from request
        lat = request.GET.get('lat')
        lon = request.GET.get('lon')
        units = request.GET.get('units', 'metric')  # Default to metric
        
        # Validate parameters
        if not lat or not lon:
            return Response(
                {'error': 'Latitude and longitude are required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Check if API key is configured
        if not OPENWEATHER_API_KEY:
            return Response(
                {'error': 'Weather API is not configured'}, 
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )
        
        # Make request to OpenWeather API
        url = f"{OPENWEATHER_BASE_URL}/forecast"
        params = {
            'lat': lat,
            'lon': lon,
            'units': units,
            'appid': OPENWEATHER_API_KEY
        }
        
        response = requests.get(url, params=params)
        data = response.json()
        
        if response.status_code != 200:
            return Response(
                {'error': data.get('message', 'Failed to fetch forecast data')},
                status=status.HTTP_502_BAD_GATEWAY
            )
        
        # Process forecast data
        forecast_items = []
        for item in data['list']:
            forecast_items.append({
                'datetime': item['dt'],
                'temperature': item['main']['temp'],
                'feels_like': item['main']['feels_like'],
                'humidity': item['main']['humidity'],
                'pressure': item['main']['pressure'],
                'weather_condition': item['weather'][0]['main'],
                'weather_description': item['weather'][0]['description'],
                'weather_icon': item['weather'][0]['icon'],
                'wind_speed': item['wind']['speed'],
                'wind_direction': item['wind']['deg'],
                'clouds': item['clouds']['all'],
                'pop': item.get('pop', 0)  # Probability of precipitation
            })
        
        forecast_data = {
            'city': data['city']['name'],
            'country': data['city']['country'],
            'timezone': data['city']['timezone'],
            'units': units,
            'forecast': forecast_items
        }
        
        return Response(forecast_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': f'An error occurred: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([AllowAny])
def get_spray_recommendations(request):
    try:
        lat = request.GET.get('lat')
        lon = request.GET.get('lon')
        units = request.GET.get('units', 'metric')

        if not lat or not lon:
            return Response({'error': 'Latitude and longitude are required'}, status=status.HTTP_400_BAD_REQUEST)

        if not OPENWEATHER_API_KEY:
            return Response({'error': 'Weather API is not configured'}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        url = f"{OPENWEATHER_BASE_URL}/forecast"
        params = {
            'lat': lat,
            'lon': lon,
            'units': units,
            'appid': OPENWEATHER_API_KEY
        }

        response = requests.get(url, params=params)
        data = response.json()

        if response.status_code != 200:
            return Response({'error': data.get('message', 'Failed to fetch forecast data')}, status=status.HTTP_502_BAD_GATEWAY)

        optimal_times, suboptimal_times, avoid_times = [], [], []

        for item in data['list']:
            dt = datetime.fromtimestamp(item['dt'])
            temp = item['main']['temp']
            humidity = item['main']['humidity']
            wind_speed = item['wind']['speed']
            weather_condition = item['weather'][0]['main']
            rain_probability = item.get('pop', 0) * 100

            time_entry = {
                'datetime': item['dt'],
                'formatted_time': dt.strftime('%Y-%m-%d %H:%M'),
                'temperature': temp,
                'humidity': humidity,
                'wind_speed': wind_speed,
                'weather_condition': weather_condition,
                'rain_probability': rain_probability,
                'reasons': []
            }

            if (weather_condition.lower() in ['clear', 'clouds'] and
                rain_probability < 20 and
                wind_speed < 5 and
                40 <= humidity <= 70 and
                10 <= temp <= 25):
                time_entry['reasons'].append('Ideal weather conditions for spraying')
                optimal_times.append(time_entry)

            elif (rain_probability >= 40 or
                  weather_condition.lower() in ['rain', 'thunderstorm', 'drizzle', 'snow'] or
                  wind_speed >= 10 or
                  temp < 5 or temp > 30):
                if rain_probability >= 40 or weather_condition.lower() in ['rain', 'thunderstorm', 'drizzle', 'snow']:
                    time_entry['reasons'].append('High chance of precipitation')
                if wind_speed >= 10:
                    time_entry['reasons'].append('Wind speed too high')
                if temp < 5:
                    time_entry['reasons'].append('Temperature too low')
                if temp > 30:
                    time_entry['reasons'].append('Temperature too high')
                avoid_times.append(time_entry)
            else:
                if rain_probability >= 20:
                    time_entry['reasons'].append('Some chance of precipitation')
                if wind_speed >= 5:
                    time_entry['reasons'].append('Moderate wind')
                if humidity < 40:
                    time_entry['reasons'].append('Low humidity')
                if humidity > 70:
                    time_entry['reasons'].append('High humidity')
                if temp < 10 or temp > 25:
                    time_entry['reasons'].append('Temperature not ideal')
                suboptimal_times.append(time_entry)

        recommendations = {
            'city': data['city']['name'],
            'country': data['city']['country'],
            'units': units,
            'optimal_times': optimal_times[:5],
            'suboptimal_times': suboptimal_times[:5],
            'avoid_times': avoid_times[:5],
            'general_advice': [
                'Spray early morning or late evening for best results',
                'Avoid spraying when rain is expected within 24 hours',
                'Low wind conditions prevent spray drift',
                'Moderate humidity helps with chemical absorption'
            ]
        }

        return Response(recommendations, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'error': f'An error occurred: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)