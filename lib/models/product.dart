// Data Model for a single product entry
class Product {
  final String id; // Firestore document ID
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String category;
  final String shopName;
  final int stock;
  final String sellerId; // Firebase Auth UID of the seller

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.shopName,
    required this.stock,
    required this.sellerId,
  });

  // Convert Product to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'category': category,
      'shopName': shopName,
      'stock': stock,
      'sellerId': sellerId,
    };
  }

  // Create Product from Firestore document
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      shopName: map['shopName'] ?? '',
      stock: map['stock'] ?? 0,
      sellerId: map['sellerId'] ?? '',
    );
  }
}

// <<< The 'dummyProducts' list has been REMOVED from this file >>>
