from io import BytesIO
import os
import tempfile
from urllib import response
from django.shortcuts import render

from ollama import Image
import requests
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import JSONParser
from rest_framework import status
import json
import re
from qdrant_client.models import Distance, VectorParams, PointStruct
import ollama
from ..services import qdrant, collection_name

# qdrant = QdrantClient(host='localhost', port=6333)
# collection_name = "closet_vectors"
dimension = 512


try:
    if not qdrant.collection_exists(collection_name):
        print(f"Collection '{collection_name}' does not exist, creating it...")
        qdrant.create_collection(
            collection_name=collection_name,
            vectors_config=VectorParams(size=dimension, distance=Distance.COSINE)
        )
except Exception as e:
    print(f"Error checking or creating collection: {e}")
    raise

# qdrant.recreate_collection(
#     collection_name=collection_name,
#     vectors_config=VectorParams(size=dimension, distance=Distance.COSINE)
# )

class ClassifyClothingView(APIView):
    parser_classes = [JSONParser]

    def post(self, request):
        image_url = request.data.get('image_url')
        if not image_url:
            return Response({"error": "Image URL is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        image_bytes = requests.get(image_url).content
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
            tmp.write(image_bytes)
            tmp_path = tmp.name

        try:
            # result = self.pipeline(tmp_path)
            metadata = self.classify_image(tmp_path)
        finally:
            os.remove(tmp_path)  # clean up

        # result['image_url'] = image_url

        # print('Scheduling background task for clothing item processing...')
        # from ..background_task import process_clothing_item_background
        # process_clothing_item_background.delay(image_url, metadata)

        return Response({
            "image_url": image_url,
            "brand": "",
            "name": metadata['name'].capitalize(),
            "category": metadata.get('category', 'others').capitalize(),
            "color": metadata['color'].capitalize(),
            "style": metadata['style'].capitalize(),
            "season": metadata['season'].capitalize(),
            "vector_id": "",  # populated later
            "description": "",  # populated later
        }, status=status.HTTP_200_OK)
    

    def classify_image(self, image_path: str) -> dict:
        prompt = """
        You are a fashion AI assistant. Given an image of a clothing item, classify it by returning a JSON object with the following fields:

        - name
        - category (must be from: tops, bottoms, dress, shoes, bags, outerwear, jewelry, accessories, others, overalls)
        - color
        - style (must be from: Athleisure, Casual, Night-time Party, Cocktail, Black Tie, Business Casual, Beach, Professional)
        - season (must be from: Spring, Summer, Autumn, Winter)

        Return only a valid JSON object with these keys. Be concise but accurate in your classification.
        """
        response = ollama.chat(
            model='moondream:latest', #gemma3:4b
            messages=[
                {"role": "system", "content": "You are a fashion item classification machine."},
                {"role": "user", "content": prompt, "images": [image_path]}
            ]
        )
        raw = response['message']['content']
        match = re.search(r'\{.*?\}', raw, re.DOTALL)
        if match:
            return json.loads(match.group())
        else:
            raise ValueError("No valid JSON found in classification response")

    


