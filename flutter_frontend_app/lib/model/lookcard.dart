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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.tertiary,
            width: 2
          ),
          boxShadow:[
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary.withAlpha(80),
              blurRadius: 30,
              spreadRadius: 5,
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
                    style: Theme.of(context).textTheme.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.bookmark_border,color: Colors.black,),
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
              style: Theme.of(context).textTheme.bodySmall),
            
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
