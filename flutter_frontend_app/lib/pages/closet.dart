import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend_app/model/clothing_item.dart';
import 'package:flutter_frontend_app/pages/LookBook.dart';
import 'package:flutter_frontend_app/pages/update_clothing.dart';
import 'package:image_picker/image_picker.dart';
import '../model/category.dart';
import 'add_clothing.dart';
import '../services/api.dart';
import 'package:auto_route/auto_route.dart';
@RoutePage()
class ClosetPage extends StatefulWidget {
  const ClosetPage({super.key});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  ////////////////////
  // State variables
  ////////////////////
  String selectedCategory = 'All';
  bool newestFirst = false;

  List<Map<String, dynamic>> allClothes = [];

  String? selectedBrand;
  String? selectedColor;


  ////////////////////
  //Methods
  ///////////////////

  Future<void> _fetchClothingItems() async {
    try {
      final result = await ApiService.getClosetItems();
      setState(() {
        allClothes = List<Map<String, dynamic>>.from(result);
      });
    } catch (e) {
      print('❌ Failed to fetch clothes: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchClothingItems();
  }

  List<String> get availableBrands {
    final brands = allClothes.map((item) => item['brand']?.toString() ?? '').toSet();
    return brands.where((b) => b.isNotEmpty).toList();
  }

  List<String> get availableColors {    
    final colors = allClothes.map((item) => item['color']?.toString() ?? '').toSet();
    return colors.where((c) => c.isNotEmpty).toList();
  }   

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
  }


  List<String> get categories => [
  ...Category.values.map((e) => categoryLabel(e)),];

  void _onAddClothingPressed() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => _imageSourceSelector(ctx),
    );

    if (!mounted || source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);

    if (!mounted || picked == null) return;
    print('Uploading image path in closet.dart: ${picked.path}');

    _showLoadingDialog('Uploading and classifying image...');

    final file = File(picked.path);
    final fileName = 'clothes/${DateTime.now().millisecondsSinceEpoch}.jpg';
    print('File name for upload to Firebase: $fileName');
    final ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putFile(file);
    final imageURL = await ref.getDownloadURL();
    print('✅ Uploaded to Firebase. Public image URL: $imageURL');

    final result = await ApiService.uploadAndClassifyImage(imageURL);

    // ✅ Declare item first
    late ClothingItem item;

    if (result != null) {
      item = ClothingItem(
        imagePath: picked.path,
        brand: result['brand'] ?? '',
        description: '',
        name: result['name'] ?? '',
        category: parseCategory(result['category']),
        color: result['color'] ?? '',
        style: result['style'] ?? '',
        season: result['season'] ?? '',
        vectorId: '',
        imageUrl: result['image_url'] ?? imageURL,
      );
    } else {
      // Fallback if classification fails
      item = ClothingItem(
        imagePath: picked.path,
        imageUrl: imageURL,
        brand: '',
        description: '',
        name: '',
        category: Category.others,
        color: '',
        style: '',
        season: '',
      );
    }

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    final classificationResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddClothingScreen(item: item),
      ),
    );

    if (classificationResult == true) {
      await _fetchClothingItems();
    }
  }

  Category parseCategory(String input) {
    return Category.values.firstWhere(
      (e) => categoryLabel(e).toLowerCase() == input.toLowerCase(),
      orElse: () => Category.others, // fallback
    );
  }

 //////////////////
  // Widgets
/////////////////


///MAIN BUILD 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Closet'),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_)=> const LookBookPage()),
            );
          }),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterBottomSheet),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Current closet items: ${allClothes.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: 1,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      //     BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Closet'),
      //     BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shopping'),
      //   ],
      // ),
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
    List<Map<String, dynamic>> filtered = List.from(allClothes);

    if (selectedBrand != null && selectedBrand!.isNotEmpty) {
      filtered = filtered
          .where((item) => item['brand']?.toLowerCase() == selectedBrand!.toLowerCase())
          .toList();
    }

    if (selectedColor != null && selectedColor!.isNotEmpty) {
      filtered = filtered
          .where((item) => item['color']?.toLowerCase() == selectedColor!.toLowerCase())
          .toList();
    }

    // Filter by category
    if (selectedCategory != 'All') {
      filtered = filtered
          .where((item) => item['category']?.toLowerCase() == selectedCategory.toLowerCase())
          .toList();
    }
    // Filter by newest
    if (newestFirst) {
      filtered.sort((a, b) {
        final aDateStr = a['date'] ?? '';
        print ('aDateStr: $aDateStr');
        final bDateStr = b['date'] ?? '';
        print ('bDateStr: $bDateStr');

        try {
          final aDate = DateTime.parse(aDateStr);
          final bDate = DateTime.parse(bDateStr);
          return bDate.compareTo(aDate); // descending
        } catch (_) {
          return 0;
        }
      });

      filtered = filtered.take(5).toList();
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
        return GestureDetector(
          onTap:() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UpdateClothingScreen(item: item),
              ),
            );
          },
        
        
        child: Card(
          child: Column(
            children: [
              Expanded(
                child: Image.network(item['image_url']!, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(item['brand'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          )
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Filter Closet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: selectedBrand,
                hint: const Text('Select Brand'),
                items: availableBrands
                    .map((brand) => DropdownMenuItem(
                          value: brand,
                          child: Text(brand),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedBrand = value);
                },
                isExpanded: true,
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: selectedColor,
                hint: const Text('Select Color'),
                items: availableColors
                    .map((color) => DropdownMenuItem(
                          value: color,
                          child: Text(color),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedColor = value);
                },
                isExpanded: true,
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {}); // Refresh filters
                },
                child: const Text('Apply Filters'),
              ),
              const SizedBox(height:8),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedBrand = null;
                    selectedColor = null;
                  });
                  // Navigator.pop(context);
                },
                child: const Text('Reset Filters'),
              )
            ],
          ),
        );
      },
    );
  }
} // End of ClosetPage class
