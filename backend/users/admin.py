from django.contrib import admin

from django.contrib import admin
from .models import CustomUser, DiseaseInfo, CommunityPost, Comment, PostLike, UserProfile, Plant

# Register your models here.
admin.site.register(CustomUser)
admin.site.register(DiseaseInfo)
admin.site.register(CommunityPost)
admin.site.register(Comment)
admin.site.register(PostLike)
admin.site.register(UserProfile)
admin.site.register(Plant)
