import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {

  // Helper untuk format Rupiah
  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  // Fungsi untuk menampilkan dialog edit nama toko
  void _showEditShopNameDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final TextEditingController _shopNameController =
    TextEditingController(text: authProvider.currentUser?.shopName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Toko'),
        content: TextField(
          controller: _shopNameController,
          decoration: const InputDecoration(labelText: 'Nama Toko'),
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Simpan'),
            onPressed: () async {
              if (_shopNameController.text.isNotEmpty) {
                await authProvider.updateShopName(_shopNameController.text);
                if (mounted) Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // Ambil nama toko saat ini
    final String currentShopName = authProvider.currentUser?.shopName ?? 'Toko Saya';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
      ),
      // USE STREAM BUILDER TO FETCH DATA REAL-TIME
      body: StreamBuilder<List<Order>>(
        stream: orderProvider.getShopOrders(currentShopName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          // --- HITUNG STATISTIK (CALCULATE STATS) ---
          double totalSales = 0;
          int totalOrders = orders.length;

          for (var order in orders) {
            for (var item in order.items) {
              // Only count sales for THIS shop (in case of mixed orders)
              if (item.shopName == currentShopName) {
                totalSales += (item.price * item.quantity);
              }
            }
          }
          // ------------------------------------------

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- BAGIAN HEADER TOKO ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.store, size: 35, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nama Toko Anda:', style: TextStyle(fontSize: 12)),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    currentShopName,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _showEditShopNameDialog(context),
                                  tooltip: 'Ubah Nama Toko',
                                )
                              ],
                            ),
                            // Display address if available
                            if (authProvider.currentUser?.addresses.isNotEmpty ?? false)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        authProvider.currentUser!.addresses.first.fullAddress,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                Text(
                  'Statistik Toko',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                // --- KARTU STATISTIK ---
                _buildStatCard(
                  context: context,
                  title: 'Total Penjualan',
                  value: _formatRupiah(totalSales),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                _buildStatCard(
                  context: context,
                  title: 'Total Pesanan',
                  value: totalOrders.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}