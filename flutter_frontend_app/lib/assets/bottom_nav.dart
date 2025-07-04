import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.lightBlueAccent,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.blueGrey,
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home),label: 'Home',),
        BottomNavigationBarItem(icon: Icon(Icons.checkroom),label: 'Closet',),
        BottomNavigationBarItem(icon: Icon(Icons.chat),label: 'AI Chat',),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart),label: 'Shopping List',),
        BottomNavigationBarItem(icon: Icon(Icons.person),label: 'Profile',),
      ],
    );
  }
}

