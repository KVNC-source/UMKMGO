import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../models/address.dart';
import 'manage_address_page.dart';
import 'dart:math';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Address? selectedAddress;
  String? selectedPayment;

  // --- LOGIKA BARU: Daftar Pembayaran ---
  final List<Map<String, dynamic>> paymentMethods = [
    {'name': 'Bayar di Tempat (COD)', 'active': true},
    {'name': 'Bank Transfer BNI (Coming Soon)', 'active': false},
    {'name': 'Kartu Kredit/Debit (Coming Soon)', 'active': false},
    {'name': 'E-Wallet (Coming Soon)', 'active': false},
  ];
  // --------------------------------------

  final double shippingFee = 15000;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null && authProvider.currentUser!.addresses.isNotEmpty) {
      selectedAddress = authProvider.currentUser!.addresses.first;
    }
    // Set default ke yang aktif (COD)
    selectedPayment = paymentMethods.firstWhere((m) => m['active'] == true)['name'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cart = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final availableAddresses = authProvider.currentUser?.addresses ?? [];

    final total = cart.subtotal + shippingFee;
    final totalFormatted = _formatRupiah(total);
    final isCheckoutReady = selectedAddress != null && selectedPayment != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Alamat Pengiriman'),
                  _buildAddressSelectionCard(
                    context,
                    title: 'Pilih Alamat',
                    value: selectedAddress,
                    icon: Icons.location_on_outlined,
                    options: availableAddresses,
                    onSelect: (value) => setState(() => selectedAddress = value),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Metode Pembayaran'),
                  _buildPaymentSelectionCard(
                    context,
                    title: 'Pilih Pembayaran',
                    value: selectedPayment,
                    icon: Icons.payment,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Ringkasan Order'),
                  _buildOrderSummary(context, cart),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildPaymentBar(context, totalFormatted, primaryColor, cart, isCheckoutReady),
        ],
      ),
    );
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildAddressSelectionCard(
      BuildContext context, {
        required String title,
        required Address? value,
        required IconData icon,
        required List<Address> options,
        required ValueChanged<Address?> onSelect,
      }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAddressSelectionDialog(context, title, options, onSelect),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
                    const SizedBox(height: 4),
                    Text(
                      value?.fullAddress ?? 'Pilih atau tambah alamat',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: value != null ? Theme.of(context).colorScheme.onSurface : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSelectionCard(
      BuildContext context, {
        required String title,
        required String? value,
        required IconData icon,
      }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPaymentSelectionDialog(context, title),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
                    const SizedBox(height: 4),
                    Text(
                      value ?? 'Pilih salah satu',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: value != null ? Theme.of(context).colorScheme.onSurface : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddressSelectionDialog(BuildContext context, String title, List<Address> options, ValueChanged<Address?> onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16.0), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ListTile(
              leading: Icon(Icons.add_location_alt_outlined, color: Theme.of(context).colorScheme.primary),
              title: const Text('Tambah Alamat Baru'),
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageAddressPage())); },
            ),
            const Divider(),
            ...options.map((option) => ListTile(
              leading: Icon(option.label.toLowerCase() == 'rumah' ? Icons.home_outlined : Icons.business_outlined),
              title: Text(option.label, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(option.fullAddress),
              onTap: () { onSelect(option); Navigator.pop(context); },
            )).toList(),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  void _showPaymentSelectionDialog(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16.0), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            // --- LOGIKA BARU: Hanya render yang aktif atau beri visual 'disabled' ---
            ...paymentMethods.map((method) {
              final bool isActive = method['active'];
              return ListTile(
                title: Text(
                  method['name'],
                  style: TextStyle(color: isActive ? Theme.of(context).colorScheme.onSurface : Colors.grey),
                ),
                enabled: isActive, // Nonaktifkan klik jika tidak aktif
                trailing: isActive ? null : const Text('Coming Soon', style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: isActive ? () {
                  setState(() => selectedPayment = method['name']);
                  Navigator.pop(context);
                } : null,
              );
            }).toList(),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartProvider cart) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${cart.items.length} Barang (${cart.totalQuantity} Total Unit)', style: const TextStyle(fontWeight: FontWeight.w600)),
            const Divider(),
            _buildSummaryRow('Subtotal Produk', _formatRupiah(cart.subtotal)),
            _buildSummaryRow('Biaya Pengiriman', _formatRupiah(shippingFee)),
            const Divider(height: 20, thickness: 1.5),
            _buildSummaryRow('Total Pembayaran', _formatRupiah(cart.subtotal + shippingFee), isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: 14, color: isTotal ? Theme.of(context).colorScheme.onSurface : Colors.grey.shade700)),
          Text(value, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, fontSize: isTotal ? 16 : 14, color: isTotal ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }

  Widget _buildPaymentBar(BuildContext context, String totalFormatted, Color primaryColor, CartProvider cart, bool isCheckoutReady) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Pembayaran', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
              Text(totalFormatted, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          SizedBox(
            height: 45,
            child: ElevatedButton(
              onPressed: (isCheckoutReady && !_isProcessing) ? () => _showOrderConfirmation(context, cart) : null,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              child: _isProcessing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Buat Pesanan'),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderConfirmation(BuildContext context, CartProvider cart) {
    final orderModel = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final total = cart.subtotal + shippingFee;

    // --- LOGIKA BARU: Tentukan status awal berdasarkan metode pembayaran ---
    final initialStatus = (selectedPayment != null && selectedPayment!.contains('COD'))
        ? 'Pesanan Diproses'
        : 'Menunggu Pembayaran';
    // ------------------------------------------------------------------------

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Konfirmasi Pesanan', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pastikan pesanan Anda sudah benar.'),
              const SizedBox(height: 10),
              Text('Total: ${_formatRupiah(total)}'),
              Text('Alamat: ${selectedAddress?.fullAddress}'),
              Text('Pembayaran: $selectedPayment'),
            ],
          ),
          actions: <Widget>[
            TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
              child: const Text('Beli Sekarang'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                setState(() { _isProcessing = true; });

                try {
                  final currentUser = authProvider.currentUser;
                  if (currentUser == null) throw Exception("User not logged in");

                  final newOrder = Order(
                    orderId: 'INV-${Random().nextInt(99999)}',
                    buyerId: currentUser.uid,
                    date: DateTime.now(),
                    totalAmount: total,
                    address: selectedAddress!.fullAddress,
                    paymentMethod: selectedPayment!,
                    status: initialStatus, // <<< Status otomatis di-set di sini
                    items: cart.items.map((item) => OrderProductItem.fromCartItem(item)).toList(),
                  );

                  await orderModel.placeOrder(newOrder, currentUser.uid);
                  cart.clearCart();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan berhasil dibuat!')));
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e')));
                } finally {
                  if (mounted) setState(() { _isProcessing = false; });
                }
              },
            ),
          ],
        );
      },
    );
  }
}