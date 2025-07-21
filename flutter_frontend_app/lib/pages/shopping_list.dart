// home.dart
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend_app/model/category.dart';
import 'package:flutter_frontend_app/pages/update_clothing.dart';
import 'package:flutter_frontend_app/services/api.dart';
import 'package:image_picker/image_picker.dart';

@RoutePage() 
class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  String? _selectedCategory;
  final _formKey = GlobalKey<FormState>();
  XFile? _pickedFile;
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];

  List<String> get _categories => [
    ...Category.values
        .map((e) => categoryLabel(e))
        .where((label) => label != "All" && label != "Newest First"),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
          elevation: 0,
        ),
        body: Stack(
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Shopping Assistant",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Should I buy this? Let me help you! Take or Upload a picture and I will show you similar items in your closet',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,

                        children: [
                          
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Category',
                              labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondary,
                              ),
                              // Default border 
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSecondary),
                              ),
                              
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSecondary),
                              ),
                              
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.onSecondary,
                                  width: 2, 
                                ),
                              ),
                              
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSecondary),
                              ),
                              
                            ),
                            value: _selectedCategory,
                            dropdownColor: Theme.of(context).colorScheme.secondary,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                            items: _categories
                                .map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Please select a category' : null,
                          ),
                          const SizedBox(height: 24),

                          
                          _buildImagePicker(),

                          const SizedBox(height: 32),

                          
                          ElevatedButton(
                            onPressed: () async {
                              if (_pickedFile != null && _selectedCategory != null) {
                                setState(() {
                                  _isLoading = true;
                                  _results = [];
                                });
                                final result = await ApiService.uploadImageWithCategory(
                                  imageFile: _pickedFile!,
                                  category: _selectedCategory!,
                                );
                                print("🎯 Received result: $result");
                                setState(() {
                                  _isLoading = false;
                                  _results = List<Map<String, dynamic>>.from(result!['results']);
                                });
                              }
                            },
                            child: const Text('Should I get it?'),
                          ),

                          const SizedBox(height: 24),

                          if (_isLoading) const Center(child: CircularProgressIndicator()),

                          if (_results.isNotEmpty) ...[
                            const Text(
                              'Similar Items Found',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            for (var item in _results) _buildItemCard(item),
                          ]
                        ],
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
  
  

  Widget _buildItemCard(Map<String, dynamic> item) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UpdateClothingScreen(item: item),
          ),
        );
      },
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            // Image or fallback
            item['image_url'] != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Image.network(
                      item['image_url'],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: Center(
                      child: Text(
                        item['name']?[0] ?? '?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ),
                  ),

            const SizedBox(width: 12),

            // Text content (name + similarity)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['name'] ?? 'Unnamed item',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Similarity: ${(item['score'] * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary.withAlpha(70),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}



Widget _buildImagePicker() {
  return Container(
    height: 180,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: _pickedFile == null ? Border.all(color: Colors.grey) : null,
    ),
    clipBehavior: Clip.antiAlias,
    child: _pickedFile != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_pickedFile!.path),
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Take a picture or upload an image',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera),
                      label: const Text('Take Picture'),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.camera);
                        if (pickedFile != null) {
                          setState(() {
                            _pickedFile = pickedFile;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Image'),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            _pickedFile = pickedFile;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
  );
}


}
