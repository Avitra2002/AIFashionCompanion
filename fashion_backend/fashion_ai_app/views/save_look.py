from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

from ..firebase_utils import upload_collage_image, save_look_to_firestore
from firebase_admin import firestore

class SaveLookView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        try:
            uid = request.data.get("uid")
            look_name = request.data.get("look_name")
            template = request.data.get("template")
            description = request.data.get("description")
            collage_base64 = request.data.get("collage_base64")
            items = request.data.get("items", [])

            if not uid or not look_name or not collage_base64:
                return Response({"error": "Missing required fields"}, status=400)

            collage_url = upload_collage_image(uid, look_name, collage_base64)

            item_ids = [item["id"] for item in items]
            item_names = [item["name"] for item in items]

            firestore_data = {
                "look_name": look_name,
                "template": template,
                "description": description,
                "collage_url": collage_url,
                "item_ids": item_ids,
                "item_names": item_names,
                "created_at": firestore.SERVER_TIMESTAMP,
            }

            save_look_to_firestore(uid, firestore_data)

            return Response({"success": True, "collage_url": collage_url}, status=201)

        except Exception as e:
            return Response({"error": str(e)}, status=500)
