import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import 'dart:math';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? selectedAddress;
  String? selectedPayment;

  final List<String> availableAddresses = [
    'Jl. Kenangan No. 12, Jakarta Selatan, 12780',
    'Kantor Sembilan, Sudirman, Jakarta Pusat, 10220',
  ];

  // Only allow COD as a selectable payment method.
  final List<String> paymentMethods = ['Bayar di Tempat (COD)'];

  // Other payment methods kept for display purposes (show these as "Coming Soon").
  final List<String> comingSoonPaymentMethods = [
    'Bank Transfer BNI',
    'Kartu Kredit/Debit',
    'E-Wallet (GoPay/OVO)',
  ];

  final String comingSoon = "Coming Soon";

  final double shippingFee = 15000;

  @override
  void initState() {
    super.initState();
    selectedAddress = availableAddresses.first;
    selectedPayment = paymentMethods.first;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cart = Provider.of<CartProvider>(context);

    final subtotal = cart.subtotal;
    final total = subtotal + shippingFee;

    final totalFormatted = _formatRupiah(total);

    final isCheckoutReady = selectedAddress != null && selectedPayment != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  _buildSelectionCard(
                    context,
                    title: 'Pilih Alamat',
                    value: selectedAddress,
                    icon: Icons.location_on_outlined,
                    options: availableAddresses,
                    onSelect: (value) =>
                        setState(() => selectedAddress = value),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Metode Pembayaran'),
                  _buildPaymentSelectionCard(context),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Ringkasan Order'),
                  _buildOrderSummary(context, cart),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildPaymentBar(
            context,
            totalFormatted,
            primaryColor,
            cart,
            isCheckoutReady,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSelectionCard(BuildContext context) {
    final allMethods = [...paymentMethods, ...comingSoonPaymentMethods];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: allMethods.map((method) {
            final enabled = paymentMethods.contains(method);
            final isSelected = selectedPayment == method;
            return ListTile(
              leading: Icon(
                Icons.payment,
                color: enabled
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              title: Text(
                method,
                style: TextStyle(
                  fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
                  color: enabled ? null : Colors.grey,
                ),
              ),
              trailing: enabled
                  ? (isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : Icon(Icons.radio_button_unchecked))
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Coming Soon',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
              onTap: enabled
                  ? () => setState(() => selectedPayment = method)
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
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

  Widget _buildSelectionCard(
    BuildContext context, {
    required String title,
    required String? value,
    required IconData icon,
    required List<String> options,
    required ValueChanged<String?> onSelect,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showSelectionDialog(context, title, options, onSelect),
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
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value ?? 'Pilih salah satu',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: value != null
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.red,
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

  void _showSelectionDialog(
    BuildContext context,
    String title,
    List<String> options,
    ValueChanged<String?> onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...options
                .map(
                  (option) => ListTile(
                    title: Text(option),
                    onTap: () {
                      onSelect(option);
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
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
            Text(
              '${cart.items.length} Barang (${cart.totalQuantity} Total Unit)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Divider(),
            _buildSummaryRow('Subtotal Produk', _formatRupiah(cart.subtotal)),
            _buildSummaryRow('Biaya Pengiriman', _formatRupiah(shippingFee)),
            const Divider(height: 20, thickness: 1.5),
            _buildSummaryRow(
              'Total Pembayaran',
              _formatRupiah(cart.subtotal + shippingFee),
              isTotal: true,
            ),
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
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: 14, // <<< FIXED: Was 4, now 14
              color: isTotal
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isTotal
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBar(
    BuildContext context,
    String totalFormatted,
    Color primaryColor,
    CartProvider cart,
    bool isCheckoutReady,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
              Text(
                totalFormatted,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 45,
            child: ElevatedButton(
              onPressed: isCheckoutReady
                  ? () => _showOrderConfirmation(context, cart)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              child: const Text('Buat Pesanan'),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderConfirmation(BuildContext context, CartProvider cart) {
    final orderModel = Provider.of<OrderProvider>(context, listen: false);
    final total = cart.subtotal + shippingFee;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Pesanan Berhasil Dibuat!',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Terima kasih atas pesanan Anda.'),
              const SizedBox(height: 10),
              Text('Total: ${_formatRupiah(total)}'),
              Text('Alamat: $selectedAddress'),
              Text('Pembayaran: $selectedPayment'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Lanjut Belanja'),
              onPressed: () {
                final newOrder = Order(
                  orderId: 'INV-${Random().nextInt(99999)}',
                  date: DateTime.now(),
                  totalAmount: total,
                  address: selectedAddress!,
                  paymentMethod: selectedPayment!,
                  items: cart.items
                      .map((item) => OrderProductItem.fromCartItem(item))
                      .toList(),
                );

                orderModel.addOrder(newOrder);
                cart.clearCart();

                Navigator.of(dialogContext).pop(); // Close dialog
                Navigator.of(context).pop(); // Close checkout page
              },
            ),
          ],
        );
      },
    );
  }
}
