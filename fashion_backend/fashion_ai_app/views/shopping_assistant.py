from qdrant_client.models import Filter, FieldCondition, MatchValue, SearchRequest
import tempfile
import cv2
from PIL import Image as PILImage

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from ..services import qdrant, collection_name, clip_model, clip_processor
from ..background_task import extract_clothing_item
import torch
import numpy as np
import os
from ..firebase_utils import get_item_data_by_vector_id 

YOLO_CATEGORY_LABELS = {
    "tops": ["shirt", "t-shirt", "blouse", "tank top", "polo", "sweater"],
    "bottoms": ["pants", "trousers", "jeans", "shorts", "leggings"],
    "dress": ["dress", "gown"],
    "shoes": ["shoes", "sneakers", "heels", "boots", "loafers"],
    "bags": ["bag", "handbag", "backpack", "purse"],
    "outerwear": ["jacket", "coat", "blazer", "hoodie", "cardigan"],
    "jewelry": ["necklace", "bracelet", "ring", "earrings"],
    "accessories": ["scarf", "hat", "belt", "gloves", "watch"],
    "overalls": ["overalls", "jumpsuit", "romper"],
    "others": ["clothes", "apparel", "garment"]
}

class SimilaritySearchAPIView(APIView):
    permission_classes = [AllowAny]

    def encode_image_with_clip_pil(self,pil_image):
        inputs = clip_processor(images=pil_image, return_tensors="pt")
        with torch.no_grad():
            outputs = clip_model.get_image_features(**inputs)
        return outputs[0].numpy()
    
    def normalize(self,vector):
        norm = np.linalg.norm(vector)
        if norm == 0:
            return vector
        return vector / norm
    
    def search_similar_vectors(self, query_vector, category, top_k=3):
        return qdrant.search(
            collection_name=collection_name,
            query_vector=query_vector,
            limit=top_k,
            query_filter=Filter(
                must=[
                    FieldCondition(key="type", match=MatchValue(value="image")),
                    FieldCondition(key="category", match=MatchValue(value=category.lower())),
                ]
            ),
            with_payload=True
        )

    def post(self, request, *args, **kwargs):
        uploaded_file = request.FILES.get('image')
        category = request.POST.get('category')
        uid = request.POST.get("uid")

        if not uploaded_file or not category:
            return Response({'error': 'Image and category are required.'},
                            status=status.HTTP_400_BAD_REQUEST)

        # Save uploaded image to a temp file
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp_file:
            for chunk in uploaded_file.chunks():
                tmp_file.write(chunk)
            tmp_file_path = tmp_file.name

        try:
            # Extract item using YOLO + SAM
            extracted_image = extract_clothing_item(tmp_file_path, category=category)
            if extracted_image is None:
                return Response({'error': 'No clothing item detected'}, status=400)

            
            extracted_pil = PILImage.fromarray(cv2.cvtColor(extracted_image, cv2.COLOR_BGR2RGB))

            
            vector = self.normalize(self.encode_image_with_clip_pil(extracted_pil))

            # Search Qdrant
            results = self.search_similar_vectors(vector, category=category)

            formatted =[]
            for r in results:
                item_id = r.payload.get("item_id")
                if item_id:
                    item_data = get_item_data_by_vector_id(uid, item_id)
                    if item_data:
                        formatted.append({
                            'firestore_id':item_data['firestore_id'],
                            'name': item_data['name'],
                            'image_url': item_data['image_url'],
                            'score': round(r.score,2),
                            'brand': item_data['brand'],
                            'color': item_data['color'],
                            'style': item_data['style'],
                            'season': item_data['season'],
                            'category': item_data['category']

                        
                        })

            return Response({'results': formatted}, status=200)

        finally:
            os.remove(tmp_file_path)