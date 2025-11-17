import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- CORRECTED IMPORTS ---
import 'package:umkmgo/providers/wishlist_provider.dart';
import 'package:umkmgo/views/shared/product_detail.dart';
// -------------------------

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = Provider.of<WishlistProvider>(context);

    return Scaffold(
      body: wishlist.items.isEmpty
          ? Center(
              child: Text(
                'You haven\'t saved any items yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: wishlist.items.length,
              itemBuilder: (context, index) {
                final product = wishlist.items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: ListTile(
                    leading: Image.network(
                      product.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(product.shopName),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        // Remove from wishlist
                        wishlist.toggleFavorite(product);
                      },
                    ),
                    onTap: () {
                      // Go to product detail page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailPage(product: product),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
