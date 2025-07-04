// home.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage() // 👈 This tells auto_route to generate HomeRoute for HomePage
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Profile')),
    );
  }
}
