from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def predict_disease(request):
    # Placeholder for your disease prediction logic
    return JsonResponse({
        'prediction': 'Healthy',
        'confidence': 0.95,
        'message': 'This is a placeholder response. Implement your ML model here.'
    })

@api_view(['POST'])
@permission_classes([AllowAny])
def predict_disease_anonymous(request):
    # Placeholder for anonymous disease prediction
    return JsonResponse({
        'prediction': 'Healthy',
        'confidence': 0.95,
        'message': 'This is a placeholder response for anonymous users.'
    })