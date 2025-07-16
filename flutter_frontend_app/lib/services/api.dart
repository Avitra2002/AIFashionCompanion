import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

///
//CRUD CALLS
// This service handles API calls for the AI Fashion Companion app

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// 1. Upload image and get AI classification
  static Future<Map<String, dynamic>?> uploadAndClassifyImage(String imageUrl) async {
    print("📡 Sending image to /api/classify/...: $imageUrl");

    final url = Uri.parse('$baseUrl/api/classify/');

    final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'image_url': imageUrl}),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    print('❌ Classification via URL failed: ${response.statusCode}');
    return null;
  }
}

  /// 2. Save clothing item to DB
  static Future<bool> saveClothingItem(Map<String, dynamic> itemData) async {
    print('Saving clothing item POST: $itemData');
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user!.getIdToken(); // Firebase ID token

    final url = Uri.parse('$baseUrl/api/closet-items/');

    print("waiting for response from $url with token $idToken");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(itemData),
    );

    return response.statusCode == 201;
  }

  /// 3. Read all clothing items
  static Future<List<Map<String, dynamic>>> getClosetItems() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user!.getIdToken(); // Firebase ID token
    print('Fetching closet items with token: $idToken');

    final url = Uri.parse('$baseUrl/api/closet-items/all/');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception('❌ Failed to load clothing items');
    }
  }

  // 4. Update clothing item
  static Future<bool> updateClothingItem(String id, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user!.getIdToken();

    final url = Uri.parse('$baseUrl/api/closet-items/$id/');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }

  // 5. chat with AI
  static Future<String> chatWithAI(String message) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user!.getIdToken();  
    final url = Uri.parse('$baseUrl/api/chat/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization' : 'Bearer $idToken',
      },
      body: jsonEncode({'message': message}),
    ); 
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['reply'] ?? 'No response from AI.';
    } else {
      throw Exception('❌ Failed to chat with AI: ${response.statusCode}');
    }

  }
}
