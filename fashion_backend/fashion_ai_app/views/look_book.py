from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from ..firebase_utils import get_look_book

class GetSavedLooksView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        uid = request.user.username  # from Firebase decoded token

        try:
            # db = firestore.client()
            # looks_ref = db.collection("users").document(uid).collection("look_book")
            # docs = looks_ref.stream()

            # looks = []
            # for doc in docs:
            #     data = doc.to_dict()
            #     data["id"] = doc.id
            #     looks.append(data)
            looks = get_look_book(uid)

            return Response(looks, status=200)

        except Exception as e:
            return Response({"error": str(e)}, status=500)
