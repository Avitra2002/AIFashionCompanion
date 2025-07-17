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
  static Future<List<Map<String, dynamic>>> chatWithAI(String message) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user!.getIdToken();
    final uid = user.uid;

    final url = Uri.parse('$baseUrl/api/chat/');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'message': message, 'uid': uid}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('❌ Failed to chat with AI: ${response.statusCode}');
    }
  }

  // 6. Save look
  static Future<bool> saveLook(Map<String, dynamic> look) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user!.getIdToken();
    final uid = user.uid;

    final url = Uri.parse('$baseUrl/api/save_look/');

    final body = {
      "uid": uid,
      "look_name": look["look_name"],
      "template": look["template"],
      "description": look["description"],
      "collage_base64": look["collage_base64"],
      "items": look["items"],  // List of { id, name }
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print("❌ Failed to save look: ${response.statusCode}");
      print(response.body);
      return false;
    }
  }


}
