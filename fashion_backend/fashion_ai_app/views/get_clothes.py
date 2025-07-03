from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from fashion_ai_app.models import ClothingItem , ClothingItemSerializer
from ..firebase_utils import get_clothing_items_from_firestore
class GetClothingItemsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        uid = request.user.username 
        try:
            items = get_clothing_items_from_firestore(uid)
            return Response(items, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)