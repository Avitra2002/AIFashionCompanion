from datetime import datetime, timedelta, timezone
from io import BytesIO
import firebase_admin
from firebase_admin import credentials, firestore, storage
import base64
from PIL import Image



if not firebase_admin._apps:
    
    cred = credentials.Certificate('firebase_service_account.json')
    firebase_admin.initialize_app(cred, {
        'storageBucket': 'ai-fashion-app-e61ed.firebasestorage.app'
    })

db = firestore.client()

def get_storage_bucket():
    return storage.bucket('ai-fashion-app-e61ed.firebasestorage.app')

def save_clothing_item_to_firestore(data, uid):
    doc_ref = db.collection("users").document(uid).collection("clothing_items").document(str(data["id"]))
    doc_ref.set(data)

def get_clothing_items_from_firestore(uid):
    items_ref = db.collection("users").document(uid).collection("clothing_items")
    docs = items_ref.stream()
    
    items = []
    for doc in docs:
        item = doc.to_dict()
        item['id'] = doc.id  
        items.append(item)
    
    return items

def update_clothing_item_in_firestore(uid, item_id, data):
    doc_ref = db.collection("users").document(uid).collection("clothing_items").document(item_id)
    if doc_ref.get().exists:
        doc_ref.update(data)
        return True
    else:
        return False
    

def get_item_data_by_vector_id(uid, vector_id_text):
    vector_id_text = vector_id_text.replace("-", "")
    collection = db.collection("users").document(uid).collection("clothing_items")
    docs = collection.where("vector_id_text", "==", vector_id_text).stream()
    for doc in docs:
        data = doc.to_dict()
        return {
            "image_url": data["image_url"],
            "firestore_id": doc.id,
            "name": data.get("name", "")
        }
    return None

def upload_collage_image(uid, look_name, base64_str):
    collage_data = base64_str.split(",")[-1]
    image_bytes = base64.b64decode(collage_data)
    image = Image.open(BytesIO(image_bytes))

    filename = f"look_book_collages/{uid}/{look_name.replace(' ', '_')}.jpg"
    bucket = get_storage_bucket()
    blob = bucket.blob(filename)

    buffer = BytesIO()
    image.save(buffer, format="JPEG")
    buffer.seek(0)
    blob.upload_from_file(buffer, content_type="image/jpeg")

    collage_url = blob.generate_signed_url(datetime.now(timezone.utc) + timedelta(days=365))

    return collage_url


def save_look_to_firestore(uid, look_data):
    doc_ref = db.collection("users").document(uid).collection("look_book").document()
    doc_ref.set(look_data)