from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from fashion_ai_app.models import ClothingItem, ClothingItemSerializer
from rest_framework.permissions import IsAuthenticated
from google.cloud import firestore

from ..firebase_utils import save_clothing_item_to_firestore
# class SaveClothingItemView(APIView):
#     def post(self, request):
#         # Mock: print and return what was sent
#         data = request.data
#         print("🧥 Received clothing item:", data)

#         # Return a mock success response
#         return Response({
#             'success': True,
#             'message': 'Mock item saved!',
#             'item': data
#         }, status=status.HTTP_201_CREATED)



class SaveClothingItemView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        serializer = ClothingItemSerializer(data=request.data)
        if serializer.is_valid():
            #Save to Django DB
            instance = serializer.save(user=request.user)

            # Prepare Firestore data
            firestore_data = serializer.data
            firestore_data["date"] = firestore.SERVER_TIMESTAMP  # Use Firestore timestamp

            
            firebase_uid = request.user.username 

            # nested Firestore path
            save_clothing_item_to_firestore(firestore_data, firebase_uid)

            return Response({'success': True, 'item': serializer.data}, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)