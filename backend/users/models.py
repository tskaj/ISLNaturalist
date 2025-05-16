from django.db import models
from django.conf import settings
from django.contrib.auth.models import AbstractUser

class CustomUser(AbstractUser):
    # Add any additional fields you need
    bio = models.TextField(blank=True)
    profile_image = models.ImageField(upload_to='profile_pics/', blank=True, null=True)
    
    def __str__(self):
        return self.username

class DiseaseInfo(models.Model):
    disease_name = models.CharField(max_length=100, unique=True)
    description = models.TextField()
    treatment = models.TextField()
    prevention = models.TextField()
    
    def __str__(self):
        return self.disease_name

class CommunityPost(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    image = models.ImageField(upload_to='community_posts/')
    caption = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    likes = models.ManyToManyField(settings.AUTH_USER_MODEL, related_name='liked_posts', blank=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Post by {self.user.username} on {self.created_at.strftime('%Y-%m-%d')}"
    
    @property
    def like_count(self):
        return self.likes.count()

class Comment(models.Model):
    post = models.ForeignKey(CommunityPost, on_delete=models.CASCADE, related_name='comments')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        # Fix the unterminated f-string on line 50
        return f"Comment by {self.user.username} on {self.post}"

# Add these models to your models.py file

class PostLike(models.Model):
    REACTION_CHOICES = [
        ('like', 'Like'),
        ('love', 'Love'),
        ('laugh', 'Laugh'),
        ('wow', 'Wow'),
        ('sad', 'Sad'),
        ('angry', 'Angry'),
    ]
    
    post = models.ForeignKey(CommunityPost, on_delete=models.CASCADE, related_name='post_likes')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    reaction_type = models.CharField(max_length=10, choices=REACTION_CHOICES, default='like')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('post', 'user')

    def __str__(self):
        return f"{self.user.username} {self.reaction_type}s {self.post.id}"


class UserProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='profile')
    bio = models.TextField(blank=True)
    profile_picture = models.ImageField(upload_to='profile_pics/', blank=True, null=True)
    location = models.CharField(max_length=100, blank=True)
    expertise_level = models.CharField(
        max_length=20,
        choices=[
            ('beginner', 'Beginner'),
            ('intermediate', 'Intermediate'),
            ('advanced', 'Advanced'),
            ('expert', 'Expert'),
        ],
        default='beginner'
    )
    favorite_plants = models.TextField(blank=True)
    joined_date = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Profile of {self.user.username}"


class Plant(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='plants')
    name = models.CharField(max_length=100)
    species = models.CharField(max_length=100, blank=True)
    image = models.ImageField(upload_to='plants/', blank=True, null=True)
    acquisition_date = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True)
    last_watered = models.DateField(null=True, blank=True)
    watering_frequency = models.IntegerField(default=7, help_text="Days between watering")
    last_fertilized = models.DateField(null=True, blank=True)
    fertilizing_frequency = models.IntegerField(default=30, help_text="Days between fertilizing")
    
    def __str__(self):
        return f"{self.name} ({self.species})"
    
    @property
    def days_since_watering(self):
        if not self.last_watered:
            return None
        from django.utils import timezone
        import datetime
        today = timezone.now().date()
        return (today - self.last_watered).days
    
    @property
    def needs_water(self):
        if not self.last_watered or not self.watering_frequency:
            return False
        return self.days_since_watering >= self.watering_frequency


class PlantCareReminder(models.Model):
    REMINDER_TYPES = [
        ('water', 'Water'),
        ('fertilize', 'Fertilize'),
        ('repot', 'Repot'),
        ('prune', 'Prune'),
        ('other', 'Other'),
    ]
    
    plant = models.ForeignKey(Plant, on_delete=models.CASCADE, related_name='reminders')
    reminder_type = models.CharField(max_length=10, choices=REMINDER_TYPES)
    due_date = models.DateField()
    completed = models.BooleanField(default=False)
    completed_date = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True)
    
    def __str__(self):
        return f"{self.get_reminder_type_display()} reminder for {self.plant.name}"
    
    @property
    def is_overdue(self):
        from django.utils import timezone
        return not self.completed and self.due_date < timezone.now().date()


class Achievement(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    icon = models.CharField(max_length=50)  # Store icon name/code
    points = models.IntegerField(default=10)
    
    def __str__(self):
        return self.name

class UserAchievement(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='achievements')
    achievement = models.ForeignKey(Achievement, on_delete=models.CASCADE)
    date_earned = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'achievement')
    
    def __str__(self):
        return f"{self.user.username} earned {self.achievement.name}"


class CommunityChallenge(models.Model):
    title = models.CharField(max_length=100)
    description = models.TextField()
    start_date = models.DateField()
    end_date = models.DateField()
    image = models.ImageField(upload_to='challenges/', blank=True, null=True)
    participants = models.ManyToManyField(
        settings.AUTH_USER_MODEL, 
        through='ChallengeParticipation',
        related_name='challenges'
    )
    
    def __str__(self):
        return self.title
    
    @property
    def is_active(self):
        from django.utils import timezone
        today = timezone.now().date()
        return self.start_date <= today <= self.end_date
    
    @property
    def participant_count(self):
        return self.participants.count()

class ChallengeParticipation(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    challenge = models.ForeignKey(CommunityChallenge, on_delete=models.CASCADE)
    joined_date = models.DateTimeField(auto_now_add=True)
    completed = models.BooleanField(default=False)
    submission_image = models.ImageField(upload_to='challenge_submissions/', blank=True, null=True)
    submission_text = models.TextField(blank=True)
    
    class Meta:
        unique_together = ('user', 'challenge')
    
    def __str__(self):
        return f"{self.user.username} in {self.challenge.title}"


class PlantIdentificationHistory(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='identification_history',
        null=True,  # Allow anonymous identifications
        blank=True
    )
    image = models.ImageField(upload_to='identification_history/')
    result = models.CharField(max_length=100)
    confidence = models.FloatField()
    date_created = models.DateTimeField(auto_now_add=True)
    saved_to_collection = models.BooleanField(default=False)
    
    def __str__(self):
        user_str = self.user.username if self.user else "Anonymous"
        return f"Identification by {user_str}: {self.result}"


class Notification(models.Model):
    NOTIFICATION_TYPES = [
        ('like', 'Like'),
        ('comment', 'Comment'),
        ('follow', 'Follow'),
        ('achievement', 'Achievement'),
        ('reminder', 'Plant Care Reminder'),
        ('challenge', 'Challenge'),
        ('system', 'System'),
    ]
    
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='notifications'
    )
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='sent_notifications'
    )
    content = models.TextField()
    object_id = models.PositiveIntegerField(null=True, blank=True)  # ID of the related object
    created_at = models.DateTimeField(auto_now_add=True)
    read = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Notification to {self.recipient.username}: {self.get_notification_type_display()}"


class UserFollow(models.Model):
    follower = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='following'
    )
    followed = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='followers'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('follower', 'followed')
    
    def __str__(self):
        return f"{self.follower.username} follows {self.followed.username}"


class PlantCareTip(models.Model):
    title = models.CharField(max_length=100)
    content = models.TextField()
    image = models.ImageField(upload_to='care_tips/', blank=True, null=True)
    category = models.CharField(
        max_length=20,
        choices=[
            ('watering', 'Watering'),
            ('light', 'Light'),
            ('soil', 'Soil'),
            ('fertilizing', 'Fertilizing'),
            ('pests', 'Pest Control'),
            ('propagation', 'Propagation'),
            ('general', 'General Care'),
        ]
    )
    difficulty_level = models.CharField(
        max_length=20,
        choices=[
            ('beginner', 'Beginner'),
            ('intermediate', 'Intermediate'),
            ('advanced', 'Advanced'),
        ],
        default='beginner'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.title