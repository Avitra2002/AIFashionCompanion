from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from ..firebase_utils import get_item_from_firestore_by_id, update_clothing_item_in_firestore

class UpdateClothingItemView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, item_id):
        uid = request.user.username
        try:
            item = get_item_from_firestore_by_id(uid, item_id)
            if item:
                return Response(item, status=status.HTTP_200_OK)
            else:
                return Response({'error': 'Item not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def put(self, request, item_id):
        uid = request.user.username
        data = request.data

        try:
            updated = update_clothing_item_in_firestore(uid, item_id, data)
            if updated:
                return Response({'message': 'Item updated'}, status=status.HTTP_200_OK)
            else:
                return Response({'error': 'Item not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
