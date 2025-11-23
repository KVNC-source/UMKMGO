import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Use relative imports for files in the same folder structure
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';
import 'checkout_page.dart'; // <<< RELATIVE IMPORT

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cart = Provider.of<CartProvider>(context);

    final itemsByShop = <String, List<CartItem>>{};
    for (var item in cart.items) {
      final shopName = item.product.shopName;
      if (!itemsByShop.containsKey(shopName)) {
        itemsByShop[shopName] = [];
      }
      itemsByShop[shopName]!.add(item);
    }

    final subtotalFormatted = cart.subtotal.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Scaffold(
      body: cart.items.isEmpty
          ? Center(
        child: Text(
          'Keranjang Anda kosong!',
          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...itemsByShop.entries.map((entry) {
                    final shopName = entry.key;
                    final shopItems = entry.value;
                    final isLastShop = entry.key == itemsByShop.keys.last;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CartPage._buildShopHeader(context, shopName, primaryColor),
                        ...shopItems.map((item) => CartPage._buildCartItem(context, item, primaryColor)),
                        if (!isLastShop) ...[
                          const SizedBox(height: 15),
                          const Divider(height: 1, thickness: 1, color: Colors.black12),
                          const SizedBox(height: 15),
                        ]
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          CartPage._buildTotalBar(context, cart, subtotalFormatted, primaryColor),
        ],
      ),
    );
  }

  static Widget _buildShopHeader(BuildContext context, String shopName, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.storefront, color: primaryColor),
            const SizedBox(width: 8),
            Text(shopName.trim(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(left: 30.0),
          child: Text('Belanja kebutuhan harianmu', style: TextStyle(color: Colors.black54)),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  static Widget _buildCartItem(BuildContext context, CartItem item, Color primaryColor) {
    final itemTotalFormatted = (item.product.price * item.quantity).toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    final pricePerUnitFormatted = item.product.price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    final unit = item.product.category.toLowerCase() == 'food' ? 'kg' : 'pcs';

    Widget imageWidget;
    if (item.product.imageUrl.isNotEmpty && Uri.tryParse(item.product.imageUrl)?.isAbsolute == true) {
      imageWidget = Image.network(
        item.product.imageUrl,
        width: 80, height: 80, fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 80, height: 80, color: Colors.grey.shade200,
          child: Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade600, size: 40),
        ),
      );
    } else {
      imageWidget = Container(
        width: 80, height: 80, color: Colors.grey.shade200,
        child: Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade600, size: 40),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: imageWidget),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16), overflow: TextOverflow.ellipsis),
                Text('Rp $pricePerUnitFormatted/$unit', style: TextStyle(color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Total: Rp $itemTotalFormatted', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          CartPage._buildQuantityControl(context, item, primaryColor),
        ],
      ),
    );
  }

  static Widget _buildQuantityControl(BuildContext context, CartItem item, Color primaryColor) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return SizedBox(
      width: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => cart.decrementQuantity(item.product),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
              child: Icon(Icons.remove, size: 18, color: primaryColor),
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
          InkWell(
            onTap: () => cart.incrementQuantity(item.product),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor),
              child: const Icon(Icons.add, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTotalBar(BuildContext context, CartProvider cart, String subtotalFormatted, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Subtotal Produk', style: TextStyle(fontSize: 14, color: Colors.black54)),
                Text('Rp $subtotalFormatted', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CheckoutPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              child: const Text('Lanjut ke Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}