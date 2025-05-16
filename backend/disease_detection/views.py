from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import api_view, permission_classes
from django.views.decorators.csrf import csrf_exempt
from .model_manager import model_manager
from .models import LeafImageDetection
from .roboflow_validation import validate_leaf_image
from .roboflow_disease import classify_disease
import os
import tempfile
import mimetypes
from PIL import Image as PILImage
import io


class DiseaseDetectionView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        if 'image' not in request.FILES:
            return Response({'error': 'No image provided'}, status=status.HTTP_400_BAD_REQUEST)
        
        image = request.FILES['image']
        crop_type = request.data.get('crop_type', 'tomato')  # Default to tomato
        
        # Validate image type
        content_type = image.content_type
        if content_type not in ['image/jpeg', 'image/jpg', 'image/png']:
            return Response({'error': 'Only JPEG and PNG images are allowed'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate image size (max 10MB)
        if image.size > 10 * 1024 * 1024:  # 10MB in bytes
            return Response({'error': 'Image size should be less than 10MB'}, status=status.HTTP_400_BAD_REQUEST)
        
        # First validate if the image contains a leaf
        image.seek(0)  # Reset file pointer
        is_leaf, confidence, success, message = validate_leaf_image(image)
        
        if not is_leaf or not success:
            return Response({
                'error': 'The uploaded image does not appear to contain a leaf',
                'message': message
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # If leaf validation passes, proceed with disease classification
        image.seek(0)  # Reset file pointer again
        success, result_data, message = classify_disease(image)
        
        if not success:
            return Response({'error': message}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Save detection to database
            detection = LeafImageDetection(
                user=request.user,
                image=image,
                crop_type=crop_type,
                prediction=result_data['prediction'],
                confidence=max(result_data['probabilities'].values())
            )
            detection.save()
            
            # Add disease information to the response
            try:
                # Get the predicted disease name
                disease_name = result_data['prediction']
                
                # Try to find disease info in the database
                from users.models import DiseaseInfo
                from .deepseek_service import DeepSeekService
                
                disease_info = DiseaseInfo.objects.filter(disease_name=disease_name).first()
                
                if disease_info:
                    # Add disease info to the result data
                    result_data['disease_info'] = {
                        'description': disease_info.description,
                        'treatments': disease_info.treatment.split('\n') if disease_info.treatment else [],
                        'prevention': disease_info.prevention.split('\n') if disease_info.prevention else []
                    }
                else:
                    # No disease info found in database, use DeepSeek API to get recommendations
                    print(f"Info: Using DeepSeek API for disease information - '{disease_name}' not found in database (expected behavior)")
                    
                    # Use mock service in development to avoid API costs
                    deepseek_result = DeepSeekService.get_mock_treatment_recommendation(disease_name, crop_type)
                    
                    if deepseek_result['success']:
                        # Parse the recommendation into sections
                        recommendation = deepseek_result['recommendation']
                        
                        # Improved parsing of the recommendation text with better section detection
                        lines = recommendation.split('\n')
                        description = ''
                        treatments = []
                        prevention = []
                        
                        current_section = 'none'
                        for line in lines:
                            line_lower = line.lower().strip()
                            if line.strip() == '':
                                continue
                            
                            # Better section detection with more specific markers
                            if 'disease information:' in line_lower:
                                current_section = 'description'
                                continue
                            elif 'treatment recommendations:' in line_lower or 'treatment:' in line_lower:
                                current_section = 'treatments'
                                continue
                            elif 'prevention measures:' in line_lower or 'prevention:' in line_lower:
                                current_section = 'prevention'
                                continue
                            elif 'organic treatments:' in line_lower or 'chemical options:' in line_lower:
                                # These are subsections of treatments, still keep in treatments section
                                continue
                            
                            # Process the line based on its section
                            if current_section == 'description':
                                description += line.strip() + ' '
                            elif current_section == 'treatments':
                                # Only add numbered items or bullet points to treatments
                                if (line.strip().startswith(('1.', '2.', '3.', '4.', '5.', '6.', '7.', '8.', '9.', '-'))):
                                    treatments.append(line.strip())
                            elif current_section == 'prevention':
                                # Only add numbered items or bullet points to prevention
                                if (line.strip().startswith(('1.', '2.', '3.', '4.', '5.', '6.', '7.', '8.', '9.', '-'))):
                                    prevention.append(line.strip())
                        
                        result_data['disease_info'] = {
                            'description': description.strip() or 'No detailed information available for this disease.',
                            'treatments': treatments,
                            'prevention': prevention
                        }
                    else:
                        # DeepSeek API failed, add empty values
                        result_data['disease_info'] = {
                            'description': 'No detailed information available for this disease.',
                            'treatments': [],
                            'prevention': []
                        }
            except Exception as e:
                print(f"Error fetching disease info: {str(e)}")
                # Don't fail the request if disease info can't be fetched
                result_data['disease_info'] = {
                    'description': 'Unable to retrieve disease information.',
                    'treatments': [],
                    'prevention': []
                }
            
            return Response(result_data, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class AnonymousDiseaseDetectionView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        if 'image' not in request.FILES:
            return Response({'error': 'No image provided'}, status=status.HTTP_400_BAD_REQUEST)
        
        image = request.FILES['image']
        crop_type = request.data.get('crop_type', 'tomato')  # Default to tomato
        
        # Validate image type
        content_type = image.content_type
        if content_type not in ['image/jpeg', 'image/jpg', 'image/png']:
            return Response({'error': 'Only JPEG and PNG images are allowed'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate image size (max 10MB)
        if image.size > 10 * 1024 * 1024:  # 10MB in bytes
            return Response({'error': 'Image size should be less than 10MB'}, status=status.HTTP_400_BAD_REQUEST)
        
        # First validate if the image contains a leaf
        image.seek(0)  # Reset file pointer
        is_leaf, confidence, success, message = validate_leaf_image(image)
        
        if not is_leaf or not success:
            return Response({
                'error': 'The uploaded image does not appear to contain a leaf',
                'message': message
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # If leaf validation passes, proceed with disease classification
        image.seek(0)  # Reset file pointer again
        success, result_data, message = classify_disease(image)
        
        if not success:
            return Response({'error': message}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Save detection to database (anonymous user)
            detection = LeafImageDetection(
                user=None,  # Anonymous user
                image=image,
                crop_type=crop_type,
                prediction=result_data['prediction'],
                confidence=max(result_data['probabilities'].values())
            )
            detection.save()
            
            # Add disease information to the response
            try:
                # Get the predicted disease name
                disease_name = result_data['prediction']
                
                # Try to find disease info in the database
                from users.models import DiseaseInfo
                from .deepseek_service import DeepSeekService
                
                disease_info = DiseaseInfo.objects.filter(disease_name=disease_name).first()
                
                if disease_info:
                    # Add disease info to the result data
                    result_data['disease_info'] = {
                        'description': disease_info.description,
                        'treatments': disease_info.treatment.split('\n') if disease_info.treatment else [],
                        'prevention': disease_info.prevention.split('\n') if disease_info.prevention else []
                    }
                else:
                    # No disease info found in database, use DeepSeek API to get recommendations
                    print(f"Info: Using DeepSeek API for disease information - '{disease_name}' not found in database (expected behavior)")
                    
                    # Use mock service in development to avoid API costs
                    deepseek_result = DeepSeekService.get_mock_treatment_recommendation(disease_name, crop_type)
                    
                    if deepseek_result['success']:
                        # Parse the recommendation into sections
                        recommendation = deepseek_result['recommendation']
                        
                        # Improved parsing of the recommendation text with better section detection
                        lines = recommendation.split('\n')
                        description = ''
                        treatments = []
                        prevention = []
                        
                        current_section = 'none'
                        for line in lines:
                            line_lower = line.lower().strip()
                            if line.strip() == '':
                                continue
                            
                            # Better section detection with more specific markers
                            if 'disease information:' in line_lower:
                                current_section = 'description'
                                continue
                            elif 'treatment recommendations:' in line_lower or 'treatment:' in line_lower:
                                current_section = 'treatments'
                                continue
                            elif 'prevention measures:' in line_lower or 'prevention:' in line_lower:
                                current_section = 'prevention'
                                continue
                            elif 'organic treatments:' in line_lower or 'chemical options:' in line_lower:
                                # These are subsections of treatments, still keep in treatments section
                                continue
                            
                            # Process the line based on its section
                            if current_section == 'description':
                                description += line.strip() + ' '
                            elif current_section == 'treatments':
                                # Only add numbered items or bullet points to treatments
                                if (line.strip().startswith(('1.', '2.', '3.', '4.', '5.', '6.', '7.', '8.', '9.', '-'))):
                                    treatments.append(line.strip())
                            elif current_section == 'prevention':
                                # Only add numbered items or bullet points to prevention
                                if (line.strip().startswith(('1.', '2.', '3.', '4.', '5.', '6.', '7.', '8.', '9.', '-'))):
                                    prevention.append(line.strip())
                        
                        result_data['disease_info'] = {
                            'description': description.strip() or 'No detailed information available for this disease.',
                            'treatments': treatments,
                            'prevention': prevention
                        }
                    else:
                        # DeepSeek API failed, add empty values
                        result_data['disease_info'] = {
                            'description': 'No detailed information available for this disease.',
                            'treatments': [],
                            'prevention': []
                        }
            except Exception as e:
                print(f"Error fetching disease info: {str(e)}")
                # Don't fail the request if disease info can't be fetched
                result_data['disease_info'] = {
                    'description': 'Unable to retrieve disease information.',
                    'treatments': [],
                    'prevention': []
                }
            
            return Response(result_data, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def validate_leaf(request):
    """
    Endpoint to validate if an uploaded image contains a leaf
    """
    if 'image' not in request.FILES:
        return Response({'error': 'No image provided'}, status=status.HTTP_400_BAD_REQUEST)
    
    image_file = request.FILES['image']
    
    # Reset file pointer to beginning
    image_file.seek(0)
    
    # Use the Roboflow validation function
    is_leaf, confidence, success, message = validate_leaf_image(image_file)
    
    return Response({
        'is_leaf': is_leaf,
        'confidence': confidence,
        'success': success,
        'message': message
    })

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def classify_plant_disease(request):
    """
    Endpoint to classify plant disease using the Pagdurusa model
    """
    if 'image' not in request.FILES:
        return Response({'error': 'No image provided'}, status=status.HTTP_400_BAD_REQUEST)
    
    image_file = request.FILES['image']
    crop_type = request.data.get('crop_type', 'tomato')  # Default to tomato
    
    # Validate image type
    content_type = image_file.content_type
    if content_type not in ['image/jpeg', 'image/jpg', 'image/png']:
        return Response({'error': 'Only JPEG and PNG images are allowed'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Validate image size (max 10MB)
    if image_file.size > 10 * 1024 * 1024:  # 10MB in bytes
        return Response({'error': 'Image size should be less than 10MB'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Reset file pointer to beginning
    image_file.seek(0)
    
    # Use the Roboflow disease classification function
    success, result_data, message = classify_disease(image_file)
    
    if success:
        # Try to fetch disease information from the database
        from users.models import DiseaseInfo
        from .deepseek_service import DeepSeekService
        
        try:
            # Get the predicted disease name
            disease_name = result_data['prediction']
            
            # Try to find disease info in the database
            disease_info = DiseaseInfo.objects.filter(disease_name=disease_name).first()
            
            if disease_info:
                # Add disease info to the result data
                result_data['disease_info'] = {
                    'description': disease_info.description,
                    'treatments': disease_info.treatment.split('\n') if disease_info.treatment else [],
                    'prevention': disease_info.prevention.split('\n') if disease_info.prevention else []
                }
            else:
                # No disease info found in database, use DeepSeek API to get recommendations
                print(f"Info: Using DeepSeek API for disease information - '{disease_name}' not found in database (expected behavior)")
                
                # Use mock service in development to avoid API costs
                deepseek_result = DeepSeekService.get_mock_treatment_recommendation(disease_name, crop_type)
                # For production, use the actual API:
                # deepseek_result = DeepSeekService.get_treatment_recommendation(disease_name, crop_type)
                
                if deepseek_result['success']:
                    # Parse the recommendation into sections
                    recommendation = deepseek_result['recommendation']
                    
                    # Improved parsing of the recommendation text with better section detection
                    lines = recommendation.split('\n')
                    description = ''
                    treatments = []
                    prevention = []
                    
                    current_section = 'none'
                    for line in lines:
                        line_lower = line.lower().strip()
                        if line.strip() == '':
                            continue
                        
                        # Better section detection with more specific markers
                        if 'disease information:' in line_lower:
                            current_section = 'description'
                            continue
                        elif 'treatment recommendations:' in line_lower or 'treatment:' in line_lower:
                            current_section = 'treatments'
                            continue
                        elif 'prevention measures:' in line_lower or 'prevention:' in line_lower:
                            current_section = 'prevention'
                            continue
                        elif 'organic treatments:' in line_lower or 'chemical options:' in line_lower:
                            # These are subsections of treatments, still keep in treatments section
                            continue
                        
                        # Process the line based on its section
                        if current_section == 'description':
                            description += line.strip() + ' '
                        elif current_section == 'treatments':
                            # Only add numbered items or bullet points to treatments
                            if (line.strip().startswith(('1.', '2.', '3.', '4.', '5.', '6.', '7.', '8.', '9.', '-'))):
                                treatments.append(line.strip())
                        elif current_section == 'prevention':
                            # Only add numbered items or bullet points to prevention
                            if (line.strip().startswith(('1.', '2.', '3.', '4.', '5.', '6.', '7.', '8.', '9.', '-'))):
                                prevention.append(line.strip())
                    
                    result_data['disease_info'] = {
                        'description': description.strip() or 'No detailed information available for this disease.',
                        'treatments': treatments,
                        'prevention': prevention
                    }
                else:
                    # DeepSeek API failed, add empty values
                    result_data['disease_info'] = {
                        'description': 'No detailed information available for this disease.',
                        'treatments': [],
                        'prevention': []
                    }
                    print(f"DeepSeek API error: {deepseek_result['message']}")
        except Exception as e:
            print(f"Error fetching disease info: {str(e)}")
            # Don't fail the request if disease info can't be fetched
            result_data['disease_info'] = {
                'description': 'Unable to retrieve disease information.',
                'treatments': [],
                'prevention': []
            }
        
        return Response({
            'success': True,
            'data': result_data
        })
    else:
        return Response({
            'success': False,
            'message': message
        }, status=status.HTTP_400_BAD_REQUEST)