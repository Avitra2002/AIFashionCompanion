import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_frontend_app/model/clothing_item.dart';
import 'package:flutter_frontend_app/services/api.dart';
import '../model/category.dart';
// import 'package:firebase_storage/firebase_storage.dart';

class AddClothingScreen extends StatefulWidget {
  final ClothingItem item;

  const AddClothingScreen({super.key, required this.item});

  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController brandCtrl;
  late TextEditingController nameCtrl;
  late TextEditingController colorCtrl;


  @override
  void initState() {
    super.initState();
    brandCtrl = TextEditingController(text: widget.item.brand);
    nameCtrl = TextEditingController(text: widget.item.name);
    colorCtrl = TextEditingController(text: widget.item.color);


    if (!styles.contains(widget.item.style)) {
      widget.item.style = 'Casual'; // Default style if not found
    }

    if (!seasons.contains(widget.item.season)) {
      widget.item.season = 'Summer'; // Default season if not found
    }


  }

  @override
  void dispose() {
    brandCtrl.dispose();
    nameCtrl.dispose();
    colorCtrl.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Clothing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.file(File(widget.item.imagePath), height: 200),
              const SizedBox(height: 16),
              // Padding(
              //   padding: const EdgeInsets.symmetric(vertical: 6),
              //   child: Align(
              //     alignment: Alignment.centerLeft,
              //     child: Text(
              //       'Description: ${widget.item.description}',
              //       style: const TextStyle(fontSize: 16),
              //     ),
              //   ),
              // ),
              _buildTextField('Brand', brandCtrl),
              _buildTextField('Name', nameCtrl),
              _buildDropdown<Category>(
                label: 'Category',
                value: (widget.item.category != Category.all &&
                      widget.item.category != Category.newest)
                  ? widget.item.category
                  : Category.tops,
                items: Category.values.where((c) => c != Category.all && c != Category.newest).toList(),
                labelBuilder: categoryLabel,
                onChanged: (val) => setState(() => widget.item.category = val!),
              ),
              _buildTextField('Color', colorCtrl),
              _buildDropdown<String>(
                label: 'Style',
                value: widget.item.style,
                items: styles,
                labelBuilder: (e) => e,
                onChanged: (val) => setState(() => widget.item.style = val!),
              ),
              _buildDropdown<String>(
                label: 'Season',
                value: widget.item.season,
                items: seasons,
                labelBuilder: (e) => e,
                onChanged: (val) => setState(() => widget.item.season = val!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    print("Form is valid");
                    widget.item.brand = brandCtrl.text;
                    widget.item.name = nameCtrl.text;
                    widget.item.color = colorCtrl.text;

                    final file = File(widget.item.imagePath);
                    print ("Selected image path in add_clothing page: ${file.path}");
                   

                    if (!file.existsSync()) {
                      print("Image file does not exist: ${file.path}");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image file not found')),
                      );
                      return;
                    }
                    // final fileName = 'clothes/${DateTime.now().millisecondsSinceEpoch}.jpg';
                    // final ref = FirebaseStorage.instance.ref().child(fileName);

                    // try {
                    //   print("Uploading image to Firebase Storage: $fileName");
                    //   // await ref.putFile(file);
                    //   final bytes = await file.readAsBytes();
                    //   print("Read ${bytes.length} bytes from image");

                    //   await ref.putData(bytes);
                    //   final imageURL = await ref.getDownloadURL();
                    //   print("Image uploaded successfully: $imageURL");
                    //   widget.item.imageUrl = imageURL; // Store the URL in the item
                    // } catch (e) {
                    //   print("Image upload failed: $e");
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(content: Text('Error uploading image')),
                    //   );
                    //   return;
                    // }


                    final itemData = {
                      'brand': widget.item.brand,
                      'name': widget.item.name,
                      'description': widget.item.description,
                      'category': categoryLabel(widget.item.category),
                      'color': widget.item.color,
                      'style': widget.item.style,
                      'season': widget.item.season,
                      'image_url': widget.item.imageUrl,
                      'vector_id': widget.item.vectorId,
                    };
                    print("Sending itemData: $itemData");
                    final success = await ApiService.saveClothingItem(itemData);
                    print("Save result: $success");

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved to closet!')),
                      );
                      Navigator.pop(context,true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error saving item')),
                      );
                    }
                  } else {
                    print("Form is invalid");
                  }
                },
                child: const Text('Save to Closet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<T>(
        value: value,
        onChanged: onChanged,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(labelBuilder(e))))
            .toList(),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (val) => val == null ? 'Required' : null,
      ),
    );
  }
}