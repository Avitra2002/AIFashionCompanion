from django.shortcuts import render

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework import status

class ClassifyClothingView(APIView):
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        image = request.FILES.get('image')

        if not image:
            return Response({'error': 'No image uploaded'}, status=status.HTTP_400_BAD_REQUEST)

        # TODO: Background removal + YOLO classification logic here

        # Mock response for now
        return Response({
            'brand': 'Gucci',
            'name': 'Mock Blazer',
            'category': 'Outerwear',
            'color': 'Black',
            'style': 'Business Casual',
            'season': 'Autumn',
        })

