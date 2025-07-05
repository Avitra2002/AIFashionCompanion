import firebase_admin
from firebase_admin import credentials, firestore

# Prevent re-initialization if already set up
if not firebase_admin._apps:
    cred = credentials.Certificate('firebase_service_account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

def save_clothing_item_to_firestore(data, uid):
    doc_ref = db.collection("users").document(uid).collection("clothing_items").document()
    doc_ref.set(data)

def get_clothing_items_from_firestore(uid):
    items_ref = db.collection("users").document(uid).collection("clothing_items")
    docs = items_ref.stream()
    
    items = []
    for doc in docs:
        item = doc.to_dict()
        item['id'] = doc.id  # Add the document ID to the item
        items.append(item)
    
    return items

def update_clothing_item_in_firestore(uid, item_id, data):
    doc_ref = db.collection("users").document(uid).collection("clothing_items").document(item_id)
    if doc_ref.get().exists:
        doc_ref.update(data)
        return True
    else:
        return False