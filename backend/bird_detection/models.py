from django.db import models
from django.utils import timezone

class BirdDetection(models.Model):
    image = models.ImageField(upload_to='bird_detections/')
    detected_species = models.CharField(max_length=255, blank=True, null=True)
    confidence = models.FloatField(default=0.0)
    detection_data = models.JSONField(blank=True, null=True)
    created_at = models.DateTimeField(default=timezone.now)
    
    def __str__(self):
        return f"{self.detected_species} ({self.confidence:.2f}) - {self.created_at}"
