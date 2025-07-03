enum Category {
  all,
  newest,
  tops,
  bottoms,
  dress,
  shoes,
  bags,
  outerwear,
  jewelry,
  accessories,
  others,
}

String categoryLabel(Category category) {
  switch (category) {
    case Category.newest:
      return 'Newest First';
    case Category.tops:
      return 'Tops';
    case Category.bottoms:
      return 'Bottoms';
    case Category.dress:
      return 'Dress';
    case Category.shoes:
      return 'Shoes';
    case Category.bags:
      return 'Bags';
    case Category.outerwear:
      return 'Outerwear';
    case Category.jewelry:
      return 'Jewelry';
    case Category.accessories:
      return 'Accessories';
    case Category.others:
      return 'Others';
    case Category.all:
      return 'All';
  }
}

const List<String> styles = [
  'Athleisure',
  'Casual',
  'Night-time Party',
  'Cocktail',
  'Black Tie',
  'Business Casual',
  'Beach',
  'Professional',
];

const List<String> seasons = [
  'Spring',
  'Summer',
  'Autumn',
  'Winter',
];
