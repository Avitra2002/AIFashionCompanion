from sentence_transformers import SentenceTransformer
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams
from transformers import CLIPModel, CLIPProcessor
from ultralytics import YOLOWorld, SAM

# Shared model instances
clip_model_chat = SentenceTransformer("sentence-transformers/clip-ViT-B-32")
qdrant = QdrantClient(host="localhost", port=6333)
collection_name = "closet_vectors"

if not qdrant.collection_exists(collection_name):
    qdrant.create_collection(
        collection_name=collection_name,
        vectors_config=VectorParams(size=512, distance=Distance.COSINE)
    )

yolo_model = YOLOWorld("yolov8s-worldv2.pt")
sam_model = SAM("mobile_sam.pt")
clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
