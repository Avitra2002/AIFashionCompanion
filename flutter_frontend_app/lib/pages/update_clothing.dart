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
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Update Clothing Item',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name',labelStyle: Theme.of(context).textTheme.titleMedium),style: Theme.of(context).textTheme.bodyMedium,),
                      const SizedBox(height: 10),
                      TextField(controller: brandController, decoration: InputDecoration(labelText: 'Brand',labelStyle: Theme.of(context).textTheme.titleMedium),style: Theme.of(context).textTheme.bodyMedium,),
                      const SizedBox(height: 10),
                      TextField(controller: colorController, decoration: InputDecoration(labelText: 'Color',labelStyle: Theme.of(context).textTheme.titleMedium),style: Theme.of(context).textTheme.bodyMedium,),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: styleController.text.isNotEmpty ? styleController.text : null,
                        dropdownColor:Theme.of(context).colorScheme.secondary ,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary, 
                        ),
                        items: styles.map((style) {
                          return DropdownMenuItem<String>(
                            value: style,
                            child: Text(style, style: Theme.of(context).textTheme.bodyMedium),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              styleController.text = value;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Style',
                          labelStyle: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: seasonController.text.isNotEmpty ? seasonController.text : null,
                        dropdownColor:Theme.of(context).colorScheme.secondary ,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary, 
                        ),
                        items: seasons.map((season) {
                          return DropdownMenuItem<String>(
                            value: season,
                            child: Text(season, style: Theme.of(context).textTheme.bodyMedium),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              seasonController.text = value;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Season',
                          labelStyle: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),

                      const SizedBox(height: 10),
                      DropdownButtonFormField<Category>(
                        value: selectedCategory,
                        dropdownColor:Theme.of(context).colorScheme.secondary ,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary, 
                        ),
                        items: Category.values.where((category) =>
                            categoryLabel(category) != 'All' &&
                            categoryLabel(category) != 'Newest First')
                          .map((category) {
                          return DropdownMenuItem<Category>(
                            value: category,
                            child: Text(categoryLabel(category),style:Theme.of(context).textTheme.bodyMedium,),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                        decoration: InputDecoration(labelText: 'Category',labelStyle: Theme.of(context).textTheme.titleMedium),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: ElevatedButton(
                            onPressed: _updateItem,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Update Item'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



}
