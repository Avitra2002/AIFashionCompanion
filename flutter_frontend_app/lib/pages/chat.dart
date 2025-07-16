// home.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend_app/model/category.dart';
import 'package:flutter_frontend_app/model/clothing_item.dart';
import 'package:flutter_frontend_app/pages/chat_interface.dart';
import 'package:flutter_frontend_app/routes/app_router.dart';
import 'package:flutter_frontend_app/services/api.dart';

@RoutePage()
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Future<List<ClothingItem>> _itemsFuture;
  final requiredCategories = [
    Category.tops,
    Category.bottoms,
    Category.shoes,
  ];


  @override
  void initState() {
    super.initState();
    _itemsFuture = ApiService.getClosetItems()
    .then((jsonList) => jsonList.map(clothingItemFromJson).toList());
  }

  Map<Category, List<ClothingItem>> groupItemsByCategory(List<ClothingItem> items) {
    final Map<Category, List<ClothingItem>> map = {};

    for (var item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }

    return map;
  }

  // set a rule that there needs to be at least 3 items of each category in the closet to use the feature --> meaningful results
  // if there are less than 3 items, show a message to the user to add more
  // if there are more than 3 items, show the AI chat feature

  bool hasMinimumRequiredItems(Map<Category, List<ClothingItem>> groupedItems) {
    for (var category in requiredCategories) {
      if (!groupedItems.containsKey(category) || groupedItems[category]!.length < 3) {
        return false;
      }
    }
    return true;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Stylist Chat')),
      body: FutureBuilder<List<ClothingItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data!;
          final grouped = groupItemsByCategory(items);
          final isEligible = hasMinimumRequiredItems(grouped);

          return isEligible
              ? const ChatInterface()
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'You need at least 3 Tops, 3 Bottoms, and 3 Pairs of Shoes to use the AI stylist.',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ...requiredCategories.map((category) {
                        final count = grouped[category]?.length ?? 0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${categoryLabel(category)}: $count / 3',
                              style: const TextStyle(fontSize: 14),
                            ),
                            LinearProgressIndicator(
                              value: (count / 3).clamp(0.0, 1.0),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.pushRoute(const ClosetRoute());
                          },
                          child: const Text('Add More Clothing'),
                        ),
                    ],
                  ),

                    );
            }),
        );
  }
}
