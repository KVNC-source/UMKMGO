// lib/models/product.dart
class Product {
  final String id;
  final String sellerId; // <<< ENSURE THIS IS HERE
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String category;
  final String shopName;
  final int stock;

  Product({
    this.id = '',
    required this.sellerId, // <<< REQUIRED
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.shopName,
    required this.stock,
  });

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      sellerId: map['sellerId'] ?? '', // <<< MAP IT
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      shopName: map['shopName'] ?? '',
      stock: (map['stock'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId, // <<< SAVE IT
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'category': category,
      'shopName': shopName,
      'stock': stock,
    };
  }
}