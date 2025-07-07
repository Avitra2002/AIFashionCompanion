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
