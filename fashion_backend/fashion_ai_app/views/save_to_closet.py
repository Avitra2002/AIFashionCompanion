from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from fashion_ai_app.models import ClothingItem, ClothingItemSerializer
from rest_framework.permissions import IsAuthenticated
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
            serializer.save(user=request.user)
            return Response({'success': True, 'item': serializer.data}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)