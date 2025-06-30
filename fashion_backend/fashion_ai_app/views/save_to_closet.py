from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

class SaveClothingItemView(APIView):
    def post(self, request):
        # Mock: print and return what was sent
        data = request.data
        print("🧥 Received clothing item:", data)

        # Return a mock success response
        return Response({
            'success': True,
            'message': 'Mock item saved!',
            'item': data
        }, status=status.HTTP_201_CREATED)
