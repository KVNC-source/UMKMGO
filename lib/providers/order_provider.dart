// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ... (getUserOrders and getShopOrders remain the same)
  Stream<List<Order>> getUserOrders(String userId) {
    return _firestore.collection('users').doc(userId).collection('orders').orderBy('date', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)).toList());
  }
  Stream<List<Order>> getShopOrders(String shopName) {
    return _firestore
        .collection('orders')
        .where('shopNames', arrayContains: shopName)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)).toList();
    });
  }
  Future<void> placeOrder(Order order, String userId) async {
    final batch = _firestore.batch();

    // 1. Save to User's Personal Collection
    final userOrderRef = _firestore.collection('users').doc(userId).collection('orders').doc(order.orderId);
    batch.set(userOrderRef, order.toMap());

    // 2. Save to Global Orders Collection
    final globalOrderRef = _firestore.collection('orders').doc(order.orderId);
    batch.set(globalOrderRef, order.toMap());

    // 3. Decrement Stock
    for (var item in order.items) {
      if (item.productId.isNotEmpty) {
        final productRef = _firestore.collection('products').doc(item.productId);
        batch.update(productRef, {'stock': FieldValue.increment(-item.quantity)});
      }
    }

    try {
      await batch.commit();
      notifyListeners();
    } catch (e) {
      print("Error placing order: $e");
      throw e;
    }
  }

  // --- UPDATED: Sync Status to Buyer ---
  Future<void> updateOrderStatus(String orderId, String newStatus, String buyerId) async {
    try {
      final batch = _firestore.batch();

      // 1. Update Global Order (Seller View)
      final globalRef = _firestore.collection('orders').doc(orderId);
      batch.update(globalRef, {'status': newStatus});

      // 2. Update Buyer's Personal Order (Buyer View)
      if (buyerId.isNotEmpty) {
        final userRef = _firestore
            .collection('users')
            .doc(buyerId)
            .collection('orders')
            .doc(orderId);
        batch.update(userRef, {'status': newStatus});
      }

      await batch.commit();
      notifyListeners();
    } catch (e) {
      print("Error updating status: $e");
      throw e;
    }
  }
}