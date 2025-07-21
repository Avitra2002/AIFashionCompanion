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
  final minAmount = 8;


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
      if (!groupedItems.containsKey(category) || groupedItems[category]!.length < minAmount) {
        return false;
      }
    }
    return true;
  }


  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(toolbarHeight: 0, elevation: 0),
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

            return Stack(
              children: [
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "AI Stylist Chat",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSecondary,
                                ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Need help to put an outfit together for an occasion? Just type in the occasion!',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Main content container
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: isEligible
                              ? const ChatInterface()
                              : SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'You need at least $minAmount Tops, $minAmount Bottoms, and $minAmount Pairs of Shoes to use the AI stylist.',
                                        style: const TextStyle(fontSize: 16),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      ...requiredCategories.map((category) {
                                        final count = grouped[category]?.length ?? 0;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${categoryLabel(category)}: $count / $minAmount',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            LinearProgressIndicator(
                                              value: (count / minAmount).clamp(0.0, 1.0),
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
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
  );
}

}
