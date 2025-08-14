class Branch {
  final String id;
  final String name;
  Branch({required this.id, required this.name});
  factory Branch.fromJson(Map<String, dynamic> j) => Branch(id: j['id'], name: j['name']);
}

class Subcategory {
  final String id;
  final String name;
  Subcategory({required this.id, required this.name});
  factory Subcategory.fromJson(Map<String, dynamic> j) => Subcategory(id: j['id'], name: j['name']);
}

class Category {
  final String id;
  final String name;
  final String icon; // not used as asset, optional URL
  final String cover;
  final List<Subcategory> subcategories;
  Category({required this.id, required this.name, required this.icon, required this.cover, required this.subcategories});
  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['id'], name: j['name'], icon: j['icon'] ?? '', cover: j['cover'] ?? '',
    subcategories: (j['subcategories'] as List).map((e)=>Subcategory.fromJson(e)).toList()
  );
}

class Product {
  final String id;
  final String categoryId;
  final String subcategoryId;
  final String title;
  final String unit;
  final double price;
  final String image;
  final double rating;
  final int reviews;
  Product({
    required this.id,
    required this.categoryId,
    required this.subcategoryId,
    required this.title,
    required this.unit,
    required this.price,
    required this.image,
    required this.rating,
    required this.reviews,
  });
  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'],
    categoryId: j['categoryId'],
    subcategoryId: j['subcategoryId'],
    title: j['title'],
    unit: j['unit'] ?? '',
    price: (j['price'] as num).toDouble(),
    image: j['image'],
    rating: (j['rating'] as num).toDouble(),
    reviews: j['reviews'] ?? 0,
  );
}
