class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String status;
  final DateTime createdAt;
  final String imageUrl;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.status,
    required this.createdAt,
    required this.imageUrl,
    required this.rating,
  });
}