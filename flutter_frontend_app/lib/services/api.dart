import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// 1. Upload image and get AI classification
  static Future<Map<String, dynamic>?> uploadAndClassifyImage(File imageFile) async {
    print('📡 Sending image to /api/classify/...');

    final url = Uri.parse('$baseUrl/api/classify/');

    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      return json.decode(body);
    } else {
      print('Classification failed: ${response.statusCode}');
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

  /// 3. Get all clothing items
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

}

