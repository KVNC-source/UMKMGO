import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umkmgo/providers/order_provider.dart';
import 'package:umkmgo/providers/auth_provider.dart';
import 'package:umkmgo/models/order.dart';

class ViewOrdersPage extends StatelessWidget {
  ViewOrdersPage({super.key});

  final List<String> _orderStatuses = [
    'Menunggu Pembayaran',
    'Diproses',
    'Dikirim',
    'Selesai',
    'Dibatalkan'
  ];

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showStatusUpdateDialog(BuildContext context, Order order) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Update Status: ${order.orderId}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _orderStatuses.map((status) {
              return ListTile(
                title: Text(status),
                trailing: order.status == status
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  // <<< IMPORTANT: Pass buyerId to allow syncing with buyer's history >>>
                  orderProvider.updateOrderStatus(order.orderId, status, order.buyerId);
                  Navigator.of(dialogContext).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final shopName = authProvider.currentUser?.shopName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Orders'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              "Showing orders for: '$shopName'",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Order>>(
        stream: orderProvider.getShopOrders(shopName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Text(
                'You have no incoming orders.',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              Color statusColor = Colors.green;
              if (order.status == 'Menunggu Pembayaran') {
                statusColor = Colors.orange;
              } else if (order.status == 'Dibatalkan') {
                statusColor = Colors.red;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(),
                      Text('Date: ${_formatDate(order.date)}'),
                      Text('Total Order: ${_formatRupiah(order.totalAmount)}'),
                      Text(
                          'Status: ${order.status}',
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)
                      ),
                      const SizedBox(height: 10),
                      // Filter items to show only this shop's products
                      ...order.items.where((item) => item.shopName == shopName).map((item) =>
                          Text("- ${item.name} (x${item.quantity})")
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _showStatusUpdateDialog(context, order);
                        },
                        child: const Text('Update Status'),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}