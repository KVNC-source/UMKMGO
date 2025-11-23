import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  int get totalQuantity {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  CartItem? _findItem(Product product) {
    try {
      return _items.firstWhere((item) => item.product.name == product.name);
    } catch (e) {
      return null;
    }
  }

  // --- LOGIKA BARU: Constraint Stok ---

  // Mengembalikan true jika berhasil, false jika stok habis
  bool addToCart(Product product, {int quantity = 1}) {
    // Cek 1: Apakah stok produk kosong?
    if (product.stock <= 0) {
      return false;
    }

    final existingItem = _findItem(product);

    if (existingItem != null) {
      // Cek 2: Apakah menambah 1 lagi akan melebihi stok?
      if (existingItem.quantity + quantity > product.stock) {
        return false; // Stok tidak cukup
      }
      existingItem.quantity += quantity;
    } else {
      // Cek 3: Apakah jumlah awal melebihi stok?
      if (quantity > product.stock) {
        return false;
      }
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
    return true; // Berhasil
  }

  void incrementQuantity(Product product) {
    final item = _findItem(product);
    if (item != null) {
      // Cek Stok sebelum menambah
      if (item.quantity < product.stock) {
        item.quantity++;
        notifyListeners();
      } else {
        // Opsional: Beritahu UI bahwa batas stok tercapai (bisa lewat return bool)
      }
    }
  }
  // ------------------------------------

  void decrementQuantity(Product product) {
    final item = _findItem(product);
    if (item != null) {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _items.remove(item);
      }
      notifyListeners();
    }
  }

  void removeItem(Product product) {
    _items.removeWhere((item) => item.product.name == product.name);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}