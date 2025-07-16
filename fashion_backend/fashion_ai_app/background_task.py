from celery import shared_task
import uuid
import requests
import tempfile
import os
from PIL import Image
import cv2
import numpy as np
import torch
import json

from fashion_ai_app.firebase_utils import update_clothing_item_in_firestore
from qdrant_client.models import PointStruct

from ultralytics import YOLOWorld, SAM
from transformers import CLIPProcessor, CLIPModel
import ollama

# Load models once
yolo_model = YOLOWorld('yolov8s-worldv2.pt')
sam_model = SAM('mobile_sam.pt')
clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

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

def extract_clothing_item(image_path, category=None):
    if category:
        label_list = YOLO_CATEGORY_LABELS.get(category.lower())
        if label_list:
            print(f"Running YOLO for category: {category} -> labels: {label_list}")
            yolo_model.set_classes(label_list)
    else:
        print("No category specified, skipping YOLO detection.")
        return None  # Dont run YOLO if no category is specified

    yolo_results = yolo_model.predict(image_path)
    boxes = yolo_results[0].boxes

    if boxes is None or len(boxes) == 0:
        return None  # No detections

    areas = [(box.xyxy[0][2] - box.xyxy[0][0]) * (box.xyxy[0][3] - box.xyxy[0][1]) for box in boxes]
    largest_idx = areas.index(max(areas))
    largest_box = boxes[largest_idx]
    x1, y1, x2, y2 = map(int, largest_box.xyxy[0])
    sam_box = [x1, y1, x2, y2]

    sam_results = sam_model(image_path, bboxes=sam_box)
    mask = sam_results[0].masks.data[0].cpu().numpy().astype("uint8")

    image = cv2.imread(image_path)
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    if mask.shape != image.shape[:2]:
        mask = cv2.resize(mask, (image.shape[1], image.shape[0]), interpolation=cv2.INTER_NEAREST)

    masked_image = cv2.bitwise_and(image_rgb, image_rgb, mask=mask)
    background = np.ones_like(image_rgb) * 255
    final_image = np.where(mask[:, :, None] == 1, masked_image, background)

    return final_image

def encode_image_with_clip(image_np):
    image_pil = Image.fromarray(image_np)
    inputs = clip_processor(images=image_pil, return_tensors="pt")
    with torch.no_grad():
        outputs = clip_model.get_image_features(**inputs)
    return outputs[0].numpy()

def encode_text_with_clip(text):
    inputs = clip_processor(text=[text], return_tensors="pt", padding=True, truncation=True, max_length=77)
    with torch.no_grad():
        outputs = clip_model.get_text_features(**inputs)
    return outputs[0].numpy()

@shared_task
def process_clothing_item_background(image_url, metadata):
    # Step 1: Download image
    image_bytes = requests.get(image_url).content
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
        tmp.write(image_bytes)
        tmp_path = tmp.name

    try:
        # Step 2: Use YOLO + SAM to crop item
        clothing_image = extract_clothing_item(tmp_path, category=metadata.get('category').lower())
        if clothing_image is None:
            print("No clothing item detected. using original image instead.")
            original_image = cv2.imread(tmp_path)
            clothing_image = cv2.cvtColor(original_image, cv2.COLOR_BGR2RGB)
            

        # Save cropped image to temp
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as cropped_tmp:
            cropped_path = cropped_tmp.name
            Image.fromarray(clothing_image).save(cropped_path)

        # Step 3: Encode image using CLIP
        # image_vector = encode_image_with_clip(clothing_image)

        image_vector = encode_image_with_clip(clothing_image).astype(np.float32)

        if isinstance(metadata, str):
            try:
                metadata = json.loads(metadata)
            except Exception as e:
                print("Failed to parse metadata JSON:", e)
                metadata = {}

        # Step 4: Generate description
        prompt = f"""
        Using the following fashion item metadata, write a short product description that includes all the details: name, category, color, style, season and what occasion it would be great for. Generate only the description, no other text.
        - Name: {metadata['name']}
        - Category: {metadata['category']}
        - Color: {metadata['color']}
        - Style: {metadata['style']}
        - Season: {metadata['season']}
        """
        response = ollama.chat(
            model='gemma3:4b',
            messages=[
                {"role": "system", "content": "You are a fashion product description generator."},
                {"role": "user", "content": prompt.strip()}
            ]
        )
        description = response['message']['content'].strip()
        print ("Generated description:", description)

        lines = [line.strip() for line in description.splitlines() if line.strip()]
        cleaned_description = lines[-1] if lines else description

        print("cleaned_description:", cleaned_description)

        from .views.classify import qdrant, collection_name

        item_id = uuid.uuid4().hex
        img_id = uuid.uuid4().hex
        text_id = uuid.uuid4().hex

        # Step 5: Encode text using CLIP
        # text_vector = encode_text_with_clip(description)
        text_vector = encode_text_with_clip(cleaned_description).astype(np.float32)

        print("=== QDRANT UPSERT DEBUG ===")
        print("Image vector type:", type(image_vector.tolist()[0]))
        print("Text vector type:", type(text_vector.tolist()[0]))
        print(json.dumps({
            "points_summary": [
                {
                    "id": img_id,
                    "vector_dim": len(image_vector.tolist()),
                    "vector_preview": image_vector.tolist()[:5],
                    "payload": {"type": "image"}
                },
                {
                    "id": text_id,
                    "vector_dim": len(text_vector.tolist()),
                    "vector_preview": text_vector.tolist()[:5],
                    "payload": {
                        "type": "text",
                        "description": cleaned_description[:60] + "..." if len(cleaned_description) > 60 else cleaned_description
                    }
                }
            ]
        }, indent=2))


        # Step 6: Save both vectors to Qdrant
        
        qdrant.upsert(
            collection_name=collection_name,
            points=[
                PointStruct(id=img_id, vector=image_vector.tolist(), payload={"type": "image", "item_id": item_id}),
                PointStruct(id=text_id, vector=text_vector.tolist(), payload={"type": "text", "item_id":item_id, "description": cleaned_description})
            ]
        )

        # Step 7: Update DB
        from .models import ClothingItem
        item = ClothingItem.objects.filter(image_url=image_url).first()
        if item:
            item.description = cleaned_description
            item.vector_id = item_id
            item.save()

            # Step 8: Update Firebase
            firebase_uid = item.user.username
            firestore_data = {
                "description": cleaned_description,
                "vector_id": item_id,
                "vector_id_img": img_id,
                "vector_id_text": text_id
            }
            update_clothing_item_in_firestore(firebase_uid, str(item.id), firestore_data)

    finally:
        os.remove(tmp_path)
        if os.path.exists(cropped_path):
            os.remove(cropped_path)
