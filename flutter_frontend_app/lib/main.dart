import 'package:flutter/material.dart';
import '../pages/closet.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug, 
    );

    await initializeFirebaseUser(); // your anonymous auth for
    runApp(const MyApp());
  } catch (e, stack) {
    print("Firebase init error: $e");
    print("Stack: $stack");
  }
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in a Flutter IDE). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
  @override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Fashion Companion AI',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 165, 209, 246),
        primary: Colors.black,
        secondary: Colors.white,
        tertiary: const Color.fromARGB(255, 193, 236, 194),
      ),
      useMaterial3: true,
      fontFamily: 'Romaine',
    ),
    home: ClosetPage(),
  );
}

}