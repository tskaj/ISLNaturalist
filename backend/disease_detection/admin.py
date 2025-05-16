from django.contrib import admin
from .models import LeafImageDetection

@admin.register(LeafImageDetection)
class LeafImageDetectionAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'crop_type', 'prediction', 'confidence', 'created_at')
    list_filter = ('crop_type', 'prediction', 'created_at')
    search_fields = ('prediction', 'user__username')
    readonly_fields = ('created_at',)
    date_hierarchy = 'created_at'