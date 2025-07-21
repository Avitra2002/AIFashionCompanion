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
        print('👕 Clothes fetched: $result');
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
      body: Stack(
        children: [
          // Pink container
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Closet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon:  Icon(Icons.bookmark_border, color: Theme.of(context).colorScheme.onPrimary,),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LookBookPage()),
                            );
                          },
                        ),
                        
                      ],
                    ),
                    
                  ),
                  // Clothing item count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Current closet items: ${allClothes.length}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  SizedBox(height: 12,),
                  Center(
                    child: ElevatedButton(
                      onPressed: _onAddClothingPressed,
                      child: const Text('+ Add to closet'),
                    ),
                  ),
                

                
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 24),
                      decoration:BoxDecoration(
                        color: Theme.of(context).appBarTheme.backgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            
                            _buildCategoryChips(),

                            const SizedBox(height: 8),

                            //filter button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Items',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                IconButton(
                                  icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.onPrimary,),
                                  onPressed: _showFilterBottomSheet,
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Grid expands to fill remaining space
                            Expanded(
                              child: _buildClothesGrid(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            
                ],
              ),
            ),
          ),
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
              label: Text(category, style: TextStyle(color: isSelected ?Theme.of(context).colorScheme.onSecondary : Theme.of(context).colorScheme.secondary) ),
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
        
        
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondary.withAlpha(80),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item['image_url']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        
      ),
      
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Filter Closet', 
                style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: selectedBrand,
                  hint: Text(
                    'Select Brand',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSecondary
                        ),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.secondary, 
                  iconEnabledColor: Theme.of(context).colorScheme.secondary, 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary, 
                  ),
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSecondary, width: 2),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSecondary, width: 2),
                    ),
                  ),
                  items: availableBrands.map((brand) {
                    return DropdownMenuItem<String>(
                      value: brand,
                      child: Text(
                        brand,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedBrand = value);
                  },
                  isExpanded: true,
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: selectedColor,
                  hint: Text(
                    'Select Color',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSecondary
                        ),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.secondary, 
                  iconEnabledColor: Theme.of(context).colorScheme.secondary, 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary, 
                  ),
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSecondary, width: 2),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSecondary, width: 2),
                    ),
                  ),
                  items: availableColors.map((color) {
                    return DropdownMenuItem<String>(
                      value: color,
                      child: Text(
                        color,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                      ),
                    );
                  }).toList(),
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
                const SizedBox(height:2),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedBrand = null;
                      selectedColor = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Reset Filters',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.underline,    
                      decorationStyle: TextDecorationStyle.solid,     
                      decorationThickness: 3, 
                      color: Theme.of(context).colorScheme.onPrimary                         
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
} 
