import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../routes/app_router.dart';
import 'package:google_fonts/google_fonts.dart';

final _appRouter = AppRouter(); // Define the AppRouter instance

void main() async {
  await dotenv.load();
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
    return MaterialApp.router(
      title: 'Fashion Companion AI',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary:Color(0xFFE6E6FA),
          secondary: Color.fromARGB(255, 251, 234, 241),
          tertiary: Color(0xFFE6E6FA),
          // background: Color(0xFFFAF8FF),
          surface: Colors.grey[900]!,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Colors.black,
          onSurface: Color.fromARGB(255, 251, 234, 241),

        ),
        useMaterial3: true,
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          )
        ),
        textTheme: GoogleFonts.nunitoTextTheme(
          Theme.of(context).textTheme.copyWith(
            bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
            headlineMedium: TextStyle(fontSize: 18, color:Colors.black, fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
            titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black),
            bodySmall: TextStyle(fontSize: 14, color: const Color.fromARGB(255, 51, 51, 51))
            
          ),
        ),
    
      ),
      routerConfig: _appRouter.config(), 
    );
  }
}
