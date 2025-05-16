from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import api_view, permission_classes
from django.views.decorators.csrf import csrf_exempt
from .models import InsectDetection
from .roboflow_insect import detect_insect_species
import os
import tempfile
import mimetypes
from PIL import Image as PILImage
import io


class InsectDetectionView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        if 'image' not in request.FILES:
            return Response({'error': 'No image provided'}, status=status.HTTP_400_BAD_REQUEST)
        
        image = request.FILES['image']
        
        # Validate image type
        content_type = image.content_type
        if content_type not in ['image/jpeg', 'image/jpg', 'image/png']:
            return Response({'error': 'Only JPEG and PNG images are allowed'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate image size (max 10MB)
        if image.size > 10 * 1024 * 1024:  # 10MB in bytes
            return Response({'error': 'Image size should be less than 10MB'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Process the image with Roboflow insect detection
        success, result_data, message = detect_insect_species(image)
        
        if not success:
            return Response({
                'error': message
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Save the detection result to database
        try:
            image.seek(0)  # Reset file pointer
            detection = InsectDetection(
                image=image,
                detected_species=result_data['species'],
                confidence=result_data['confidence'],
                detection_data=result_data['detections']
            )
            detection.save()
            
            return Response({
                'success': True,
                'species': result_data['species'],
                'confidence': result_data['confidence'],
                'detections': result_data['detections'],
                'message': message
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'error': f"Error saving detection: {str(e)}"
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class AnonymousInsectDetectionView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        if 'image' not in request.FILES:
            return Response({'error': 'No image provided'}, status=status.HTTP_400_BAD_REQUEST)
        
        image = request.FILES['image']
        
        # Validate image type
        content_type = image.content_type
        if content_type not in ['image/jpeg', 'image/jpg', 'image/png']:
            return Response({'error': 'Only JPEG and PNG images are allowed'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate image size (max 10MB)
        if image.size > 10 * 1024 * 1024:  # 10MB in bytes
            return Response({'error': 'Image size should be less than 10MB'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Process the image with Roboflow insect detection
        success, result_data, message = detect_insect_species(image)
        
        if not success:
            return Response({
                'error': message
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Return the detection results without saving to database
        return Response({
            'success': True,
            'species': result_data['species'],
            'confidence': result_data['confidence'],
            'detections': result_data['detections'],
            'message': message
        }, status=status.HTTP_200_OK)
