from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
import datetime

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def post_list_create(request):
    if request.method == 'GET':
        # Return dummy posts for now
        current_time = timezone.now().isoformat()
        dummy_posts = [
            {
                'id': 1,
                'user': request.user.username,
                'caption': 'My beautiful plant collection',
                'image': '/media/posts/plant1.jpg',
                'created_at': current_time,
                'like_count': 12,
                'is_liked': True,
                'comments': [
                    {
                        'id': 1,
                        'user': 'plant_lover',
                        'text': 'Amazing collection!',
                        'created_at': current_time
                    }
                ]
            },
            {
                'id': 2,
                'user': 'garden_enthusiast',
                'caption': 'Spring flowers in my garden',
                'image': '/media/posts/garden.jpg',
                'created_at': current_time,
                'like_count': 8,
                'is_liked': False,
                'comments': []
            }
        ]
        return JsonResponse({'success': True, 'data': dummy_posts}, safe=False)
    elif request.method == 'POST':
        # Placeholder for creating a post
        return JsonResponse({
            'success': True,
            'data': {
                'id': 3,
                'user': request.user.username,
                'caption': request.data.get('caption', ''),
                'image': '/media/posts/new_placeholder.jpg',
                'created_at': timezone.now().isoformat(),
                'like_count': 0,
                'is_liked': False,
                'comments': []
            }
        }, status=201)

# Keep the rest of your functions as they are
@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def post_detail(request, pk):
    # Placeholder for post detail
    return JsonResponse({
        'id': pk,
        'user': 'testuser',
        'caption': 'Post detail',
        'image': '/media/posts/placeholder.jpg',
        'created_at': '2023-06-01T12:00:00Z',
        'like_count': 5,
        'is_liked': False,
        'comments': []
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def like_post(request, pk):
    # Placeholder for liking a post
    return JsonResponse({
        'liked': True,
        'like_count': 6
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_comment(request, pk):
    # Placeholder for adding a comment
    return JsonResponse({
        'id': 1,
        'post': pk,
        'user': request.user.username,
        'text': request.data.get('content', ''),
        'created_at': '2023-06-03T12:00:00Z'
    }, status=201)