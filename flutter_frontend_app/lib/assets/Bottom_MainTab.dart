import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend_app/routes/app_router.dart';
import './bottom_nav.dart';

@RoutePage()
class MainTabPage extends StatelessWidget {
  const MainTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: const [
        HomeRoute(),
        ClosetRoute(),
        ChatRoute(),
        ShoppingListRoute(),
        ProfileRoute(),
      ],
      bottomNavigationBuilder: (_, tabsRouter) {
        return BottomNavBar(
          currentIndex: tabsRouter.activeIndex,
          onTap: tabsRouter.setActiveIndex,
        );
      },
    );
  }
}
