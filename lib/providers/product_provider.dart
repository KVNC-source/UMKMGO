// lib/providers/product_provider.dart

import 'dart:io'; // <<< IMPORT dart:io
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // <<< IMPORT STORAGE
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // <<< STORAGE INSTANCE

  List<Product> _items = [];

  List<Product> get items => _items;

  ProductProvider() {
    fetchProducts();
  }

  void fetchProducts() {
    _firestore.collection('products').snapshots().listen((snapshot) {
      _items = snapshot.docs.map((doc) {
        return Product.fromMap(doc.data(), doc.id);
      }).toList();
      notifyListeners();
    });
  }

  // --- NEW: UPLOAD IMAGE TO FIREBASE STORAGE ---
  Future<String> uploadProductImage(File imageFile) async {
    try {
      // Create a unique filename based on timestamp
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      // Create a reference to 'product_images/filename.jpg'
      Reference ref = _storage.ref().child('product_images').child('$fileName.jpg');

      // Upload the file
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Get and return the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception("Failed to upload image");
    }
  }
  // ---------------------------------------------

  Future<void> addProduct(Product product) async {
    try {
      await _firestore.collection('products').add(product.toMap());
    } catch (e) {
      print("Error adding product: $e");
      throw e;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      print("Error deleting product: $e");
      throw e;
    }
  }

  Future<void> updateProduct(String productId, Product updatedProduct) async {
    try {
      await _firestore.collection('products').doc(productId).update(updatedProduct.toMap());
    } catch (e) {
      print("Error updating product: $e");
      throw e;
    }
  }

  List<Product> getProductsBySellerId(String uid) {
    return _items.where((product) => product.sellerId == uid).toList();
  }

  // Helper for buyer view
  List<Product> getProductsByShop(String shopName) {
    return _items.where((product) => product.shopName == shopName).toList();
  }
}