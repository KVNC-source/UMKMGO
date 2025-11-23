import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- RELATIVE IMPORTS ---
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import 'cart_page.dart';       // <<< RELATIVE
import 'profile_page.dart';    // <<< RELATIVE
import 'product_detail.dart';  // <<< RELATIVE
import 'wishlist_page.dart';   // <<< RELATIVE
// ------------------------

class ProductCatalogPage extends StatefulWidget {
  const ProductCatalogPage({super.key});

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  int _selectedIndex = 0;

  // Removed 'const' here to avoid constructor issues if sub-pages aren't const
  static final List<Widget> _pages = [
    const ProductCatalogHome(),
    const WishlistPage(),
    const CartPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    final List<String> _pageTitles = [
      'Discover Local Products',
      'My Wishlist',
      'Keranjang Saya',
      'My Profile'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          if (_selectedIndex == 2)
            TextButton(
              onPressed: () {
                Provider.of<CartProvider>(context, listen: false).clearCart();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Keranjang dikosongkan.')),
                );
              },
              child: const Text('Hapus Semua', style: TextStyle(color: Colors.red)),
            ),
          if (_selectedIndex != 2)
            Badge(
              label: Text(cart.totalQuantity.toString()),
              isLabelVisible: cart.items.isNotEmpty,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => _onItemTapped(2),
              ),
            ),
          if (_selectedIndex != 3)
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => _onItemTapped(3),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(cart.totalQuantity.toString()),
              isLabelVisible: cart.items.isNotEmpty,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: Badge(
              label: Text(cart.totalQuantity.toString()),
              isLabelVisible: cart.items.isNotEmpty,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ProductCatalogHome extends StatefulWidget {
  const ProductCatalogHome({super.key});

  @override
  State<ProductCatalogHome> createState() => _ProductCatalogHomeState();
}

class _ProductCatalogHomeState extends State<ProductCatalogHome> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Food', 'Fashion', 'Crafts'];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final searchBarColor = isDarkMode ? Colors.grey[800] : Colors.grey[200];
    final chipColor = isDarkMode ? Colors.grey[800] : Colors.grey[200];
    final chipBorderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final unselectedChipTextColor = isDarkMode ? Colors.white70 : Colors.black;

    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final allProducts = productProvider.items;

        final List<Product> filteredProducts;
        if (_selectedCategory == 'All') {
          filteredProducts = allProducts;
        } else {
          filteredProducts = allProducts
              .where((product) => product.category == _selectedCategory)
              .toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'What are you looking for today?',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: searchBarColor,
                ),
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : unselectedChipTextColor,
                      ),
                      backgroundColor: chipColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          side: BorderSide(
                            color: isSelected ? Theme.of(context).colorScheme.primary : chipBorderColor,
                          )
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(child: Text("No products found"))
                  : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return ProductCard(product: product);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailPage(product: product)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                product.imageUrl,
                key: ValueKey(product.imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.shopName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatRupiah(product.price),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () {
                          cart.addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart!'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}