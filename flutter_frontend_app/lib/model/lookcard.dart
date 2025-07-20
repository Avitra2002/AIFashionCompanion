import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_frontend_app/pages/lookDetail.dart';
import 'package:flutter_frontend_app/services/api.dart';

class LookCard extends StatelessWidget {
  final String lookName;
  final String description;
  final String collageBase64;
  final Map<String, dynamic>? lookData;

  const LookCard({
    super.key,
    required this.lookName,
    required this.description,
    required this.collageBase64,
    required this.lookData,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(collageBase64.split(',').last);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child:GestureDetector(
        onTap: () {
          Navigator.push(
            context, 
            MaterialPageRoute(
            builder: (_) => LookDetailPage(look: lookData!),
            ),
          );
        },
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row (
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    lookName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16
                  ),
                  overflow: TextOverflow.ellipsis,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () async {
                  final success = await ApiService.saveLook(lookData!);
                  final message = success
                      ? '✅ Successfully saved $lookName!'
                      : '❌ Failed to save $lookName.';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                },
              ),
              ],
            ),
            
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                bytes,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
      ),
    );

  }
}
