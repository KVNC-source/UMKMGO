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

    // Get the current user's UID to filter products
    final String currentUserId = authProvider.currentUser?.uid ?? '';

    // Use the helper method to show ONLY this seller's products
    final sellerProducts = productProvider.getProductsBySellerId(currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        // Note: "Upload Dummy Data" button has been REMOVED to prevent errors
      ),
      body: sellerProducts.isEmpty
          ? Center(
        child: Text(
          'You have not added any products yet.',
          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
        ),
      )
          : ListView.builder(
        itemCount: sellerProducts.length,
        itemBuilder: (context, index) {
          final product = sellerProducts[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(product.imageUrl),
              onBackgroundImageError: (e, s) => const Icon(Icons.image_not_supported),
            ),
            title: Text(product.name),
            subtitle: Text('Stock: ${product.stock} | ${product.category}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- EDIT BUTTON ---
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // Navigate to AddProductPage in EDIT mode
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProductPage(productToEdit: product),
                      ),
                    );
                  },
                ),
                // --- DELETE BUTTON ---
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Product?'),
                        content: Text('Are you sure you want to delete ${product.name}?'),
                        actions: [
                          TextButton(
                            child: const Text('No'),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          TextButton(
                            child: const Text('Yes'),
                            onPressed: () {
                              // Delete using the Firestore Document ID
                              productProvider.deleteProduct(product.id);
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to AddProductPage in CREATE mode (no params)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}