import json
import base64
import requests
from io import BytesIO
from PIL import Image, ImageDraw
from collections import defaultdict

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.parsers import JSONParser

from sentence_transformers import SentenceTransformer
from qdrant_client import QdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue

import ollama

from ..firebase_utils import get_item_data_by_vector_id 
import numpy as np
from ..services import clip_model_chat

# Constants
CATEGORIES = ["tops", "bottoms", "dress", "shoes", "bags", "jewelry", "outerwear"]

# Models
# clip_model = SentenceTransformer("sentence-transformers/clip-ViT-B-32")
qdrant = QdrantClient(host="localhost", port=6333)
collection_name = "closet_vectors"

def normalize(vector):
    norm = np.linalg.norm(vector)
    if norm == 0:
        return vector
    return vector / norm

# Helpers
def encode_text(text):
    return clip_model_chat.encode(text, convert_to_numpy=True).tolist()

def download_image(url):
    try:
        res = requests.get(url)
        res.raise_for_status()
        return Image.open(BytesIO(res.content)).convert("RGB")
    except Exception as e:
        print("Download failed:", e)
        return None

def create_compact_collage(category_to_image, cell_size=200, padding=20):
    from math import ceil

    categories = list(category_to_image.keys())
    cols = min(3, len(categories))
    rows = ceil(len(categories) / cols)

    width = cols * (cell_size + padding) + padding
    height = rows * (cell_size + padding) + padding
    collage = Image.new("RGB", (width, height), (255, 255, 255))
    draw = ImageDraw.Draw(collage)

    for i, category in enumerate(categories):
        row, col = divmod(i, cols)
        x = padding + col * (cell_size + padding)
        y = padding + row * (cell_size + padding)

        img = category_to_image[category].resize((cell_size, cell_size))
        collage.paste(img, (x, y))
        draw.text((x + 5, y + 5), category, fill=(0, 0, 0))

    return collage

def parse_llm_json_block(raw_text):
    if raw_text.startswith("```json"):
        raw_text = raw_text.removeprefix("```json")
    if raw_text.endswith("```"):
        raw_text = raw_text.removesuffix("```")
    return json.loads(raw_text.strip())

# Main API View
class FashionLookChatView(APIView):
    permission_classes = [AllowAny]
    parser_classes = [JSONParser]

    def post(self, request):
        user_query = request.data.get("message")
        uid = request.data.get("uid")

        if not user_query or not uid:
            return Response({"error": "Missing message or uid"}, status=400)

        try:
            # --- Embed user message ---
            query_vector = normalize(encode_text(user_query))
            grouped_items = defaultdict(list)

            for cat in CATEGORIES:
                filt = Filter(must=[
                    FieldCondition(key="type", match=MatchValue(value="text")),
                    FieldCondition(key="category", match=MatchValue(value=cat)),
                ])
                results = qdrant.search(
                    collection_name=collection_name,
                    query_vector=query_vector,
                    limit=5,
                    query_filter=filt,
                    with_payload=True
                )
                for hit in results[:3]:
                    grouped_items[cat].append({
                        "id": hit.payload.get("item_id", hit.id), #get the vector_id
                        "description": hit.payload.get("description", ""),
                        "category": cat
                    })

            # --- Build prompt ---
            item_text = ""
            for cat, items in grouped_items.items():
                item_text += f"\n{cat.upper()}:\n"
                for item in items:
                    item_text += f"  - (ID:{item['id']}): {item['description']}\n"

            prompt = f"""
                    You are a fashion stylist. Based on the user’s closet and request, create 2 complete outfits that follow these structure rules:

                    1. Template A: TOP + BOTTOM + SHOES + BAG + JEWELRY [+OUTERWEAR]
                    2. Template B: DRESS/OVERALL + SHOES + BAG + JEWELRY [+OUTERWEAR]

                    The occasion is: {user_query}  

                    Choose items from the closet below. Use each item only once. Use only items that match the occasion and weather. If an item is not suitable, skip it.
                    Try to include both templates if possible. If a DRESS or OVERALL is not available, just provide outfits using Template A.
                    When you choose a dress or overall, you can skip the top and bottom items.


                    Closet Items:
                    {item_text}

                    Return your response in the following JSON format:
                    [
                    {{
                        "look_name": "...",
                        "template": "Template A or B",
                        "description": "...",
                        "items": [
                        {{
                            "name": "item name 1",
                            "id": "item_id_1",
                            "category" : "top",
                            "description": "item description 1"
                        }},
                        {{
                            "name": "item name 2",
                            "id": "item_id_2",
                            "category" : "bottom",
                            "description": "item description 2"
                        }}
                        ]
                    }}
                    ]
                    """
            # --- Call LLM ---
            response = ollama.chat(
                model='gemma3:4b',
                messages=[
                    {"role": "system", "content": "You are a fashion stylist."},
                    {"role": "user", "content": prompt}
                ]
            )
            looks = parse_llm_json_block(response['message']['content'])
            response_payloads = []

            for look in looks:
                category_to_image = {}
                item_meta = []

                for item in look["items"]:
                    item_data = get_item_data_by_vector_id(uid, item["id"])
                    if not item_data:
                        continue

                    img = download_image(item_data["image_url"])
                    if img:
                        category = item["category"].lower()
                        category_to_image[category] = img
                        item_meta.append({
                            "id": item_data["firestore_id"],
                            "name": item_data["name"]
                        })

                if not category_to_image:
                    continue  # Skip look if no images loaded

                collage_img = create_compact_collage(category_to_image)
                buffer = BytesIO()
                collage_img.save(buffer, format="JPEG")
                collage_base64 = base64.b64encode(buffer.getvalue()).decode("utf-8")

                response_payloads.append({
                    "look_name": look["look_name"],
                    "template": look["template"],
                    "description": look["description"],
                    "collage_base64": f"data:image/jpeg;base64,{collage_base64}",
                    "items": item_meta
                })

            if not response_payloads:
                return Response({"error": "No valid looks could be created"}, status=500)

            return Response(response_payloads, status=200)

        except Exception as e:
            import traceback
            print("❌ Exception in /api/chat/:", e)
            traceback.print_exc()
            return Response({"error": str(e)}, status=500)
