from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from ..firebase_utils import get_look_book

class GetSavedLooksView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        uid = request.user.username 

        try:
            
            looks = get_look_book(uid)

            return Response(looks, status=200)

        except Exception as e:
            return Response({"error": str(e)}, status=500)
