from django.test import TestCase

# Create your tests here.
# test_vectors.py

from .background_task import extract_clothing_item, encode_image_with_clip, encode_text_with_clip
from PIL import Image
import requests
import tempfile

image_url = """https://firebasestorage.googleapis.com/v0/b/ai-fashion-app-e61ed.firebasestorage.app/o/clothes%2F1752138174695.jpg?alt=media&token=f46fe97c-28e1-492c-9081-b1df20c39b3d"""
image_bytes = requests.get(image_url).content

with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
    tmp.write(image_bytes)
    tmp_path = tmp.name

clothing_image = extract_clothing_item(tmp_path)
image_vector = encode_image_with_clip(clothing_image)
text_vector = encode_text_with_clip("test description")

print("Image vector shape:", image_vector.shape)
print("Text vector shape:", text_vector.shape)
