import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Product> _items = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _useLocalData = false;

  // Public getters
  List<Product> get items => _items;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Load dummy data as fallback
  void _loadDummyData() {
    _items = [
      Product(
        id: 'dummy1',
        name: 'Handmade Woven Bag',
        description:
            'Beautifully crafted woven bag, perfect for summer outings.',
        imageUrl: 'https://placehold.co/600x400/D2B48C/FFFFFF?text=Woven+Bag',
        price: 150000,
        category: 'Crafts',
        shopName: 'Java Crafts',
        stock: 20,
        sellerId: 'dummy-seller',
      ),
      Product(
        id: 'dummy2',
        name: 'Spicy Chili Sambal',
        description:
            'Extra spicy homemade sambal, essential for Indonesian cuisine.',
        imageUrl:
            'https://placehold.co/600x400/8B0000/FFFFFF?text=Chili+Sambal',
        price: 25000,
        category: 'Food',
        shopName: 'Sambal Mama',
        stock: 100,
        sellerId: 'dummy-seller',
      ),
      Product(
        id: 'dummy3',
        name: 'Batik Print Scarf',
        description: 'Soft cotton scarf with traditional Batik patterns.',
        imageUrl: 'https://placehold.co/600x400/004D40/FFFFFF?text=Batik+Scarf',
        price: 75000,
        category: 'Fashion',
        shopName: 'Batik Corner',
        stock: 35,
        sellerId: 'dummy-seller',
      ),
    ];
    _useLocalData = true;
  }

  // Fetch all products from Firestore
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('products')
          .get()
          .timeout(const Duration(seconds: 10));
      _items = querySnapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
      _errorMessage = ''; // Clear any previous errors on success
      _useLocalData = false;
    } catch (e) {
      print('Error fetching products: $e');
      // Use dummy data as fallback
      _loadDummyData();
      _errorMessage =
          'Using offline data. Enable Firestore in Firebase Console to save products.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch products by seller ID
  Future<void> fetchProductsBySeller(String sellerId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .get();
      _items = querySnapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to load products: $e';
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get products by shop name (for filtering)
  List<Product> getProductsByShop(String shopName) {
    return _items.where((product) => product.shopName == shopName).toList();
  }

  // Add a new product to Firestore
  Future<void> addProduct(Product product) async {
    try {
      if (_useLocalData) {
        // Add to local list when using dummy data
        final newProduct = Product(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          name: product.name,
          description: product.description,
          imageUrl: product.imageUrl,
          price: product.price,
          category: product.category,
          shopName: product.shopName,
          stock: product.stock,
          sellerId: product.sellerId,
        );
        _items.add(newProduct);
        notifyListeners();
        return;
      }

      final docRef = await _firestore
          .collection('products')
          .add(product.toMap())
          .timeout(const Duration(seconds: 10));
      final newProduct = Product(
        id: docRef.id,
        name: product.name,
        description: product.description,
        imageUrl: product.imageUrl,
        price: product.price,
        category: product.category,
        shopName: product.shopName,
        stock: product.stock,
        sellerId: product.sellerId,
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add product: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Update an existing product in Firestore
  Future<void> updateProduct(String productId, Product newProduct) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update(newProduct.toMap());
      final index = _items.indexWhere((product) => product.id == productId);
      if (index != -1) {
        _items[index] = newProduct;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update product: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Delete a product from Firestore
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId);
      _items.removeWhere((product) => product.id == productId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete product: $e';
      notifyListeners();
      rethrow;
    }
  }
}
