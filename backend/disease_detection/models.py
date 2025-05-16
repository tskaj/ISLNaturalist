from django.db import models
from django.conf import settings

class LeafImageDetection(models.Model):
    """Model to store leaf image detection history"""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='leaf_detections',
        null=True,  # Allow anonymous detections
        blank=True
    )
    image = models.ImageField(upload_to='leaf_detections/')
    crop_type = models.CharField(max_length=50, default='tomato')
    prediction = models.CharField(max_length=100)
    confidence = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        user_str = self.user.username if self.user else "Anonymous"
        return f"Leaf detection by {user_str}: {self.prediction} ({self.crop_type})"