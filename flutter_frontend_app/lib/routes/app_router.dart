import 'package:auto_route/auto_route.dart';

import '../pages/closet.dart';
import '../pages/home.dart';
import '../pages/chat.dart';
import '../pages/shopping_list.dart';
import '../pages/profile.dart';
import '../assets/bottom_MainTab.dart';


part 'app_router.gr.dart'; // This will be generated

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: MainTabRoute.page,
      initial: true,
      children: [
        AutoRoute(page: HomeRoute.page, path: ''),
        AutoRoute(page: ClosetRoute.page, path: 'closet'),
        AutoRoute(page: ChatRoute.page, path: 'chat'),
        AutoRoute(page: ShoppingListRoute.page, path: 'shopping'),
        AutoRoute(page: ProfileRoute.page, path: 'profile'),
      ],
    ),
  ];
}
