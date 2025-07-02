from rest_framework import authentication, exceptions
from firebase_admin import auth as firebase_auth
from django.contrib.auth.models import User

class FirebaseAuthentication(authentication.BaseAuthentication):
    def authenticate(self, request):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return None

        id_token = auth_header.split(' ')[1]

        try:
            decoded_token = firebase_auth.verify_id_token(id_token)
        except Exception:
            raise exceptions.AuthenticationFailed('Invalid Firebase token')

        uid = decoded_token.get('uid')
        if not uid:
            raise exceptions.AuthenticationFailed('UID missing from Firebase token')

        user, _ = User.objects.get_or_create(username=uid)
        return (user, None)
