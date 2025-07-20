// home.dart
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend_app/model/category.dart';
import 'package:flutter_frontend_app/pages/update_clothing.dart';
import 'package:flutter_frontend_app/services/api.dart';
import 'package:image_picker/image_picker.dart';

@RoutePage() // 👈 This tells auto_route to generate HomeRoute for HomePage
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
      title: const Text('Shopping Assistant'),
      ),
      body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
        key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategory,
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
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: _pickedFile ==null 
                      ? Border.all(color:Colors.grey)
                      :null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _pickedFile != null
                    ? ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(12),
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
                                if (pickedFile != null){
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
                                if (pickedFile !=null){
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
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                      if (_pickedFile != null && _selectedCategory != null) {
                        setState(() {
                          _isLoading = true;
                          _results =[];
                        });
                        final result = await ApiService.uploadImageWithCategory(
                          imageFile: _pickedFile!,
                          category: _selectedCategory!,
                        );
                        print("🎯 Received result: $result");
                        setState(() {
                          _isLoading = false;
                          _results= List<Map<String, dynamic>>.from(result!['results']);
                        });
                    }
                  },
                  child: const Text('Should I get it?'),
                ),
                const SizedBox(height: 24,),
                if (_isLoading)
                  const Center(child:CircularProgressIndicator()),

                if (_results.isNotEmpty) ...[
                  const Text (
                    'Similar Items Found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),

                  ),
                  const SizedBox(height: 12,),
                  for (var item in _results) _buildItemCard(item),
                ]
                
              ],
            ),
          ),
        ),
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
      child: ListTile(
        leading: item['image_url'] != null
            ? Image.network(item['image_url'], width: 50, height: 50, fit: BoxFit.cover)
            : CircleAvatar(child: Text(item['name']?[0] ?? '?')),
        title: Text(item['name'] ?? 'Unnamed item'),
        subtitle: Text('Similarity: ${(item['score'] * 100).toStringAsFixed(1)}%'),
      ),
    ),
  );
}

}
