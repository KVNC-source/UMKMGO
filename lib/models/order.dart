// lib/models/order.dart
import 'cart_item.dart';

// (OrderProductItem class remains unchanged)
class OrderProductItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String unit;
  final String shopName;

  OrderProductItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.shopName,
  });

  factory OrderProductItem.fromCartItem(CartItem item) {
    final unit = item.product.category.toLowerCase() == 'food' ? 'kg' : 'pcs';
    return OrderProductItem(
      productId: item.product.id,
      name: item.product.name,
      imageUrl: item.product.imageUrl,
      price: item.product.price,
      quantity: item.quantity,
      unit: unit,
      shopName: item.product.shopName,
    );
  }

  factory OrderProductItem.fromMap(Map<String, dynamic> map) {
    return OrderProductItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
      unit: map['unit'] ?? '',
      shopName: map['shopName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'shopName': shopName,
    };
  }
}

class Order {
  final String orderId;
  final String buyerId; // <<< NEW: Stores the Buyer's UID
  final DateTime date;
  final double totalAmount;
  final List<OrderProductItem> items;
  final String address;
  final String paymentMethod;
  String status;

  Order({
    required this.orderId,
    required this.buyerId, // <<< NEW
    required this.date,
    required this.totalAmount,
    required this.items,
    required this.address,
    required this.paymentMethod,
    this.status = 'Menunggu Pembayaran',
  });

  factory Order.fromMap(Map<String, dynamic> map, String documentId) {
    return Order(
      orderId: map['orderId'] ?? documentId,
      buyerId: map['buyerId'] ?? '', // <<< NEW
      date: DateTime.parse(map['date']),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      address: map['address'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      status: map['status'] ?? 'Menunggu Pembayaran',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => OrderProductItem.fromMap(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId, // <<< NEW
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'address': address,
      'paymentMethod': paymentMethod,
      'status': status,
      'items': items.map((x) => x.toMap()).toList(),
    };
  }
}