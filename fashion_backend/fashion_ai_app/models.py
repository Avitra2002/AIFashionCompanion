from django.db import models

from django.db import models
from django.contrib.auth.models import User

class ClothingItem(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='clothing_items')
    description = models.TextField(blank=True, null=True)
    brand = models.CharField(max_length=100)
    name = models.CharField(max_length=100)
    category = models.CharField(max_length=100)
    color = models.CharField(max_length=50)
    style = models.CharField(max_length=50)
    season = models.CharField(max_length=50)
    image_url = models.URLField(max_length=500) 

    vector_id = models.CharField(max_length=100, blank=True, null=True)

    date = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.name}"

from rest_framework import serializers

class ClothingItemSerializer(serializers.ModelSerializer):
    ## convert ClothingItem instances to JSON and vice versa.
    class Meta:
        model = ClothingItem
        fields = '__all__'
        read_only_fields = ['user', 'date']

