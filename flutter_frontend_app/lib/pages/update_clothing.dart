import 'package:flutter/material.dart';
import '../model/category.dart';
import '../services/api.dart';

class UpdateClothingScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const UpdateClothingScreen({super.key, required this.item});

  @override
  State<UpdateClothingScreen> createState() => _UpdateClothingScreenState();
}

class _UpdateClothingScreenState extends State<UpdateClothingScreen> {
  late TextEditingController nameController;
  late TextEditingController brandController;
  late TextEditingController colorController;
  late TextEditingController styleController;
  late TextEditingController seasonController;
  late Category selectedCategory;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item['name'] ?? '');
    brandController = TextEditingController(text: widget.item['brand'] ?? '');
    colorController = TextEditingController(text: widget.item['color'] ?? '');
    styleController = TextEditingController(text: widget.item['style'] ?? '');
    seasonController = TextEditingController(text: widget.item['season'] ?? '');

    // Parse existing category string into enum
    selectedCategory = Category.values.firstWhere(
      (e) => categoryLabel(e).toLowerCase() == (widget.item['category']?.toLowerCase() ?? ''),
      orElse: () => Category.others,
    );
  }

  Future<void> _updateItem() async {
    final updated = {
      'name': nameController.text,
      'brand': brandController.text,
      'color': colorController.text,
      'style': styleController.text,
      'season': seasonController.text,
      'category': categoryLabel(selectedCategory), // return readable string
    };

    final success = await ApiService.updateClothingItem(widget.item['id'], updated);

    if (success && mounted) {

      Navigator.pop(context, true); // Return to previous screen with success flag
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Item updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to update item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(' Clothing Item')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 10),
                TextField(controller: brandController, decoration: const InputDecoration(labelText: 'Brand')),
                const SizedBox(height: 10),
                TextField(controller: colorController, decoration: const InputDecoration(labelText: 'Color')),
                const SizedBox(height: 10),
                TextField(controller: styleController, decoration: const InputDecoration(labelText: 'Style')),
                const SizedBox(height: 10),
                TextField(controller: seasonController, decoration: const InputDecoration(labelText: 'Season')),
                const SizedBox(height: 10),
                DropdownButtonFormField<Category>(
                  value: selectedCategory,
                  items: Category.values.map((category) {
                    return DropdownMenuItem<Category>(
                      value: category,
                      child: Text(categoryLabel(category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
                  child: ElevatedButton(
                    onPressed: _updateItem,
                    style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Update Item'),
                  ),
                  ),
                ),
                const SizedBox(height: 100),

                // Center(
                //   child: SizedBox(
                //     width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
                //     child: ElevatedButton(
                //       onPressed: () {
                //          // TODO: Implement to create look
                //       },
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: Colors.lightBlueAccent,
                //         padding: const EdgeInsets.symmetric(vertical: 14),
                //       ),
                //       child: const Text('Create Look with This Item',
                //         style: TextStyle(fontSize: 16, color: Colors.white),
                //       ),
                //     ),
                //   )
                // )

              ],
            ),
          ),
        ],
      ),
    );
  }
}
