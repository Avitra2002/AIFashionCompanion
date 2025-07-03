import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_frontend_app/model/clothing_item.dart';
import 'package:image_picker/image_picker.dart';
import '../model/category.dart';
import 'add_clothing.dart';
import '../services/api.dart';

class ClosetPage extends StatefulWidget {
  const ClosetPage({super.key});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  String selectedCategory = 'All';
  bool newestFirst = false;

  // Sample data (add more items as needed)
  final List<Map<String, String>> clothes = [
    {
      'image': '../assets/images/shirt 1.jpg',
      'brand': 'Uniqlo',
      'category': 'Tops',
      'color': 'Blue',
    },
    // Add more clothes here...
  ];

  List<String> categories = [
    'Newest First',
    'Tops',
    'Bottoms',
    'Dress',
    'Shoes',
    'Bags',
    'Outerwear',
    'Jewelry',
    'Accessories',
    'Others',
  ];

  void _onAddClothingPressed() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => _imageSourceSelector(ctx),
    );
    
    if (!mounted || source == null) return;
    
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    
    if (!mounted || picked == null) return;
    print('Uploading image_ path in closet.dart: ${picked.path}');

    final result = await ApiService.uploadAndClassifyImage(File(picked.path));
    
    // final item = ClothingItem(
    //   imagePath: picked.path,
    //   brand: 'Uniqlo',
    //   name: 'Sample Shirt',
    //   category: Category.tops,
    //   color: 'Blue',
    //   style: 'Casual',
    //   season: 'Summer',
    // );
    
    if (result != null) {
      final item = ClothingItem(
        imagePath: picked.path,
        brand: result['brand'] ?? '',
        name: result['name'] ?? '',
        category: parseCategory(result['category']),
        color: result['color'] ?? '',
        style: result['style'] ?? '',
        season: result['season'] ?? '',
      );
    
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddClothingScreen(item: item),
      ),
    );
    }
  }

  Category parseCategory(String input) {
  return Category.values.firstWhere(
    (e) => categoryLabel(e).toLowerCase() == input.toLowerCase(),
    orElse: () => Category.others, // fallback
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Closet'),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Current closet items: XX'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: _onAddClothingPressed,
                child: const Text('+ Add to closet'),
              ),
            ),
          ),
          _buildCategoryChips(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Items'),
          ),
          Expanded(child: _buildClothesGrid()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Closet'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shopping'),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: categories.map((category) {
          final isSelected = (selectedCategory == category) ||
              (category == 'Newest First' && newestFirst);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  if (category == 'Newest First') {
                    newestFirst = true;
                    selectedCategory = 'All';
                  } else {
                    newestFirst = false;
                    selectedCategory = category;
                  }
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClothesGrid() {
    List<Map<String, String>> filtered = clothes;

    // Filter by category
    if (selectedCategory != 'All') {
      filtered = filtered
          .where((item) => item['category']?.toLowerCase() == selectedCategory.toLowerCase())
          .toList();
    }

    // Newest First (simulate by limiting)
    if (newestFirst) {
      filtered = filtered.take(5).toList(); // Only top 5
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: filtered.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Card(
          child: Column(
            children: [
              Expanded(
                child: Image.asset(item['image']!, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(item['brand'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _imageSourceSelector(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Upload from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
