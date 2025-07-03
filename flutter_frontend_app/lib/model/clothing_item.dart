import 'category.dart';
class ClothingItem {
  final String imagePath;
  String brand;
  String name;
  Category category;
  String color;
  String style;
  String season;
  String imageUrl; // URL of the uploaded image

  ClothingItem({
    required this.imagePath,
    this.brand = '',
    this.name = '',
    this.category = Category.tops,
    this.color = '',
    this.style = '',
    this.season = '',
    this.imageUrl = '',
  });
}
