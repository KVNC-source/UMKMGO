import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class WishlistProvider extends ChangeNotifier {
  List<Product> _items = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot>? _wishlistSubscription;

  List<Product> get items => _items;

  WishlistProvider() {
    // Listen to Authentication changes (Login/Logout)
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _initWishlistListener(user.uid);
      } else {
        _clearWishlist();
      }
    });
  }

  /// Initialize real-time listener for the logged-in user's wishlist
  void _initWishlistListener(String uid) {
    _wishlistSubscription?.cancel();
    _wishlistSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .snapshots()
        .listen((snapshot) {
      _items = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  /// Clear wishlist when user logs out
  void _clearWishlist() {
    _wishlistSubscription?.cancel();
    _items = [];
    notifyListeners();
  }

  /// Checks if a product is in the wishlist.
  /// Uses ID for accuracy, falls back to name if ID is missing (rare).
  bool isFavorite(Product product) {
    if (product.id.isNotEmpty) {
      return _items.any((item) => item.id == product.id);
    }
    return _items.any((item) => item.name == product.name);
  }

  /// Adds or removes a product from the Firestore wishlist.
  Future<void> toggleFavorite(Product product) async {
    final user = _auth.currentUser;
    if (user == null) {
      // Optional: Handle guest user (e.g., show a snackbar saying "Login required")
      print("User must be logged in to save wishlist.");
      return;
    }

    if (product.id.isEmpty) {
      print("Error: Product ID is empty, cannot save to wishlist.");
      return;
    }

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(product.id); // Use Product ID as Document ID to prevent duplicates

    try {
      if (isFavorite(product)) {
        // Remove from Firestore
        await docRef.delete();
      } else {
        // Add to Firestore
        await docRef.set(product.toMap());
      }
    } catch (e) {
      print("Error toggling wishlist: $e");
    }
  }

  @override
  void dispose() {
    _wishlistSubscription?.cancel();
    super.dispose();
  }
}