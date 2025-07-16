import 'category.dart';
class ClothingItem {
  final String imagePath;
  String description;
  String brand;
  String name;
  Category category;
  String color;
  String style;
  String season;
  String imageUrl; // URL of the uploaded image
  String vectorId; // ID of the vector in the database

  ClothingItem({
    required this.imagePath,
    this.description = '',
    this.brand = '',
    this.name = '',
    this.category = Category.tops,
    this.color = '',
    this.style = '',
    this.season = '',
    this.imageUrl = '',
    this.vectorId = ''
  });
}

ClothingItem clothingItemFromJson(Map<String, dynamic> json) {
  return ClothingItem(
    imagePath: '',
    name: json['name'] ?? '',
    brand: json['brand'] ?? '',
    description: json['description'] ?? '',
    category: categoryFromString(json['category']),
    color: json['color'] ?? '',
    style: json['style'] ?? '',
    season: json['season'] ?? '',
    imageUrl: json['image_url'] ?? '',
    vectorId: json['vector_id'] ?? '',
  );
}

Category categoryFromString(String value) {
  return Category.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => Category.tops, // default fallback
  );
}