
import 'package:firebase_auth/firebase_auth.dart';
Future<void> initializeFirebaseUser() async {
  final auth = FirebaseAuth.instance;

  if (auth.currentUser == null) {
    await auth.signInAnonymously();
    print('👤 Signed in anonymously: ${auth.currentUser?.uid}');
  } else {
    print('👤 Already signed in: ${auth.currentUser?.uid}');
  }
}