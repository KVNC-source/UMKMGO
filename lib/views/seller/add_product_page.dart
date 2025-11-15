import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  // We use a placeholder URL since image upload is not implemented
  final _imageUrlController = TextEditingController(
    text: 'https://placehold.co/600x400/00D100/FFFFFF?text=New+Product',
  );

  String _selectedCategory = 'Food';
  final List<String> _categories = ['Food', 'Fashion', 'Crafts'];

  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _saveForm() {
    // Validate the form
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Get providers (listen: false because we are in a method)
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Get the shop name from the logged-in seller
      // (This mock logic will be replaced by real auth data)
      final String sellerShopName =
          authProvider.currentUser?.email == 'seller@test.com'
          ? 'Java Crafts'
          : 'My New Shop';

      // Create the new Product object
      final newProduct = Product(
        name: _nameController.text,
        description: _descriptionController.text,
        imageUrl: _imageUrlController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        category: _selectedCategory,
        shopName: sellerShopName,
        stock: int.tryParse(_stockController.text) ?? 0,
      );

      // Add product to the provider
      productProvider.addProduct(newProduct);

      // Show success message and go back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newProduct.name} has been added.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextFormField(
                controller: _nameController,
                label: 'Product Name',
                icon: Icons.label_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              _buildTextFormField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description_outlined,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _priceController,
                      label: 'Price (Rp)',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Enter price';
                        if (double.tryParse(value) == null)
                          return 'Enter valid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _stockController,
                      label: 'Stock',
                      icon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Enter stock';
                        if (int.tryParse(value) == null)
                          return 'Enter valid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              // TODO: Replace this with an image picker (Firebase Storage)
              _buildTextFormField(
                controller: _imageUrlController,
                label: 'Image URL',
                icon: Icons.image_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter image URL';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: validator,
      ),
    );
  }
}
