import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    // Top divider line
    Container(
      height: 1,
      color: Theme.of(context).colorScheme.tertiary,
    ),
    // Actual BottomNavigationBar
    BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedItemColor: Theme.of(context).colorScheme.onPrimary,
      unselectedItemColor: Colors.blueGrey,
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Closet'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'AI Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shopping'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
  ],
    );
  }
}

