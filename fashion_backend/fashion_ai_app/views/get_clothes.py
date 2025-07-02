from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from fashion_ai_app.models import ClothingItem , ClothingItemSerializer
class GetClothingItemsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        items = ClothingItem.objects.filter(user=request.user).order_by('-date')
        serializer = ClothingItemSerializer(items, many=True)
        return Response(serializer.data)
