import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_frontend_app/pages/update_clothing.dart';
import 'package:flutter_frontend_app/services/api.dart';

class LookDetailPage extends StatefulWidget {
  final Map<String, dynamic> look;
  const LookDetailPage({super.key, required this.look});

  @override
  State<LookDetailPage> createState() => _LookDetailPageState();
}

class _LookDetailPageState extends State<LookDetailPage> {
  List<Map<String, dynamic>> itemDetails = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _normalizeLookData();
    _prepareItemData();
  }

  void _normalizeLookData() {
    // make the backend firebase data the same as the cached from /chat

    // CHAT RESPONSE FOR LOOK CREATION BEFORE SAVING

//{
//   "chat_response": {
//     "look_name": "Sporty & Chic",
//     "template": "Template B",
//     "description": "...",
//     "collage_base64": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD...",  // base64 image string
//     "items": [
//       {
//         "id": '37', //firestore_id
//         "name": "Red t-shirt"
//       },
//       {
//         "id": 36,
//         "name": "Pants"
//       },
//       {
//         "id": "46",
//         "name": "Black shoes"
//       },
//       {
//         "id": "50",
//         "name": "Handbag"
//       }
//     ]
//   }

// WHEN LOOK IS SAVED TO FIRESTORE

//   "firestore_saved_document": {
//     "look_name": "Sporty & Chic",
//     "template": "Template B",
//     "description": "...",
//     "collage_url": "https://storage.googleapis.com/.../Sporty_%26_Chic.jpg?...",
//     "created_at": "2025-07-17T16:39:56Z",
//     "item_ids": ["37", "41", "46", "50"],
//     "item_names": ["Red t-shirt", "Pants", "Black shoes", "Handbag"]
//   }
// }


    final look = widget.look;

    // If 'items' already exists, do nothing
    if (look.containsKey('items')) return;

    // If we have 'item_ids' and 'item_names', normalize into 'items'
    if (look.containsKey('item_ids') && look.containsKey('item_names')) {
      final itemIds = List<String>.from(look['item_ids']);
      final itemNames = List<String>.from(look['item_names']);

      // Combine them into a list of maps
      final items = List.generate(itemIds.length, (i) {
        return {
          'id': itemIds[i],
          'name': itemNames[i],
          'image_url': null,
        };
      });

      // Attach it back to look
      look['items'] = items;
    }
  }

  Future<void> _prepareItemData() async {
    final items = List<Map<String, dynamic>>.from(widget.look['items']);

    // If any item is missing image_url, fetch from backend
    final futures = items.map((item) async {
      if (item['image_url'] == null && item['id'] != null) {
        final fetched = await ApiService.getClosetItemById(item['id']);
        if (fetched != null) {
          return {...item, ...fetched}; // merge fetched data
        }
      }
      return item;
    });

    final results = await Future.wait(futures);
    setState(() {
      itemDetails = results.whereType<Map<String, dynamic>>().toList();
      isLoading = false;
    });
  }
  


  @override
  Widget build(BuildContext context) {
    // final collageBytes = base64Decode(widget.look['collage_base64'].split(',').last);
    Widget collageImageWidget;
    if (widget.look['collage_base64'] != null){
      try {
        final collageBytes = base64Decode(widget.look['collage_base64'].split(',').last);
        collageImageWidget = Image.memory(collageBytes, fit: BoxFit.cover);
      } catch (e) {
        collageImageWidget = const Text("Invalid base64 image");
      }
    } else if (widget.look['collage_url'] != null) {
      collageImageWidget = Image.network(widget.look['collage_url'], fit: BoxFit.cover);
    } else {
      collageImageWidget = const Text("No collage image available");
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.look['look_name'] ?? 'Look Detail')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.look['description'] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: collageImageWidget,
                  ),
                  const SizedBox(height: 24),
                  const Text("Items in this Look", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...itemDetails.isNotEmpty
                      ? itemDetails.map(_buildItemCard).toList()
                      : const [Text("No item data available.")],
                ],
              ),
            ),
    );
  }


  Widget _buildItemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // 👇 Navigate to item details screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UpdateClothingScreen(item: item), // Pass item
            ),
          );
        },
        child: ListTile(
          leading: item['image_url'] != null
              ? Image.network(item['image_url'], width: 50, height: 50, fit: BoxFit.cover)
              : CircleAvatar(child: Text(item['name']?[0] ?? '?')),
          title: Text(item['name'] ?? 'Unnamed item'),
        ),
      ),
    );
  }
}

