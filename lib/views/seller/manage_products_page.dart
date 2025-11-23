import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import 'add_product_page.dart';

class ManageProductsPage extends StatelessWidget {
  const ManageProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String currentUserId = authProvider.currentUser?.uid ?? '';
    final sellerProducts = productProvider.getProductsBySellerId(currentUserId);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Produk'), centerTitle: true),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Dark mode fix
      body: sellerProducts.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Belum ada produk.', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sellerProducts.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final product = sellerProducts[index];
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // Dark mode fix
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.imageUrl,
                          width: 80, height: 80, fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey.shade800, child: const Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(product.category, style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            Text('Stok: ${product.stock}', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                Row(
                  children: [
                    Expanded(child: TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductPage(productToEdit: product))),
                      icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Edit'), style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    )),
                    Container(width: 1, height: 30, color: Theme.of(context).dividerColor),
                    Expanded(child: TextButton.icon(
                      onPressed: () => _showDeleteDialog(context, productProvider, product),
                      icon: const Icon(Icons.delete_outline, size: 18), label: const Text('Hapus'), style: TextButton.styleFrom(foregroundColor: Colors.red),
                    )),
                  ],
                )
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductPage())),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ProductProvider provider, product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text('Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(child: const Text('Hapus', style: TextStyle(color: Colors.red)), onPressed: () { provider.deleteProduct(product.id); Navigator.of(ctx).pop(); }),
        ],
      ),
    );
  }
}