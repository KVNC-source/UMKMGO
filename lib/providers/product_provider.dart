// lib/providers/product_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // --- DATABASE OPERATIONS ONLY (Upload logic removed as per request) ---

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

  List<Product> getProductsByShop(String shopName) {
    return _items.where((product) => product.shopName == shopName).toList();
  }
}