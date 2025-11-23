import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    // --- LOGIKA BARU: Cek Stok ---
    final bool isOutOfStock = product.stock <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlist, child) {
              final isFavorited = wishlist.isFavorite(product);
              return IconButton(
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.red : null,
                ),
                onPressed: () {
                  wishlist.toggleFavorite(product);
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(
              product.imageUrl,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, size: 100, color: Colors.grey[400]),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _formatRupiah(product.price),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Oleh ${product.shopName}', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                      const Spacer(),
                      // --- UI Stok Diperbarui ---
                      Text(
                          'Stok: ${product.stock}',
                          style: TextStyle(
                              fontSize: 16,
                              color: isOutOfStock ? Colors.red : Colors.grey.shade700,
                              fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal
                          )
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Deskripsi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(product.description, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          // --- LOGIKA BARU: Disable tombol jika stok 0 ---
          onPressed: isOutOfStock ? null : () {
            final success = cart.addToCart(product);
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} masuk keranjang!'), duration: const Duration(seconds: 1)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal: Stok tidak cukup!'), backgroundColor: Colors.red));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isOutOfStock ? Colors.grey : Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: Text(isOutOfStock ? 'Stok Habis' : 'Tambah ke Keranjang'),
        ),
      ),
    );
  }
}