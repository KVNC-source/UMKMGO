// lib/views/seller/add_product_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';

class AddProductPage extends StatefulWidget {
  final Product? productToEdit;

  const AddProductPage({super.key, this.productToEdit});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  // Controller for pasting the link manually
  late TextEditingController _imageUrlController;

  String? _existingImageUrl;
  // REMOVED: File? _pickedImageFile;

  String _selectedCategory = 'Food';
  final List<String> _categories = ['Food', 'Fashion', 'Crafts'];

  bool _isInit = true;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final product = widget.productToEdit;

      _nameController = TextEditingController(text: product?.name ?? '');
      _descriptionController = TextEditingController(text: product?.description ?? '');
      _priceController = TextEditingController(text: product != null ? product.price.toStringAsFixed(0) : '');
      _stockController = TextEditingController(text: product != null ? product.stock.toString() : '');

      // Initialize URL controller
      _imageUrlController = TextEditingController(text: product?.imageUrl ?? '');

      _existingImageUrl = product?.imageUrl;

      if (product != null && _categories.contains(product.category)) {
        _selectedCategory = product.category;
      }

      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // --- HELPER: CONVERT DRIVE LINK TO DIRECT IMAGE LINK ---
  String _convertDriveUrl(String url) {
    // 1. Check if it's a standard "view" link
    // Pattern: /file/d/FILE_ID/view
    final RegExp regExp = RegExp(r'\/file\/d\/([a-zA-Z0-9_-]+)\/?');
    final match = regExp.firstMatch(url);

    if (match != null && match.groupCount >= 1) {
      final fileId = match.group(1);
      // Return the direct download/view URL format
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }

    // If it doesn't match, return original (maybe it's already correct or hosted elsewhere)
    return url;
  }

  // REMOVED: _pickImage() function

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() { _isLoading = true; });

      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not logged in')));
        setState(() { _isLoading = false; });
        return;
      }

      final String currentShopName = currentUser.shopName.isNotEmpty
          ? currentUser.shopName : 'My Shop';

      try {
        String finalImageUrl = '';

        // PRIORITY 1: Manual URL (The Google Drive Link)
        if (_imageUrlController.text.isNotEmpty) {
          // Convert raw Drive link to direct link before saving
          finalImageUrl = _convertDriveUrl(_imageUrlController.text);
        }
        // PRIORITY 2: Existing URL (if editing)
        else {
          finalImageUrl = _existingImageUrl ?? '';
        }

        if (finalImageUrl.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide an image URL')));
          setState(() { _isLoading = false; });
          return;
        }

        // CREATE OR UPDATE
        final newProduct = Product(
          id: widget.productToEdit?.id ?? '', // Empty for new
          sellerId: widget.productToEdit?.sellerId ?? currentUser.uid,
          name: _nameController.text,
          description: _descriptionController.text,
          imageUrl: finalImageUrl,
          price: double.tryParse(_priceController.text) ?? 0.0,
          category: _selectedCategory,
          shopName: currentShopName,
          stock: int.tryParse(_stockController.text) ?? 0,
        );

        if (widget.productToEdit == null) {
          await productProvider.addProduct(newProduct);
        } else {
          await productProvider.updateProduct(widget.productToEdit!.id, newProduct);
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.productToEdit == null ? 'Product Added' : 'Product Updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Determine what image to show in preview
    ImageProvider? imagePreview;

    // REMOVED: _pickedImageFile logic

    if (_imageUrlController.text.isNotEmpty) {
      // Use the converted link for preview
      imagePreview = NetworkImage(_convertDriveUrl(_imageUrlController.text));
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      imagePreview = NetworkImage(_existingImageUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveForm,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- IMAGE PREVIEW AREA ---
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: imagePreview != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image(
                    image: imagePreview,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                  ),
                )
                    : Center(child: Icon(Icons.image, size: 50, color: Colors.grey[400])),
              ),
              const SizedBox(height: 10),

              // --- PASTE URL FIELD ---
              _buildTextFormField(
                controller: _imageUrlController,
                label: 'Paste Google Drive Link Here',
                icon: Icons.link,
                onChanged: (val) {
                  // Trigger rebuild to update preview image
                  setState(() {});
                },
              ),

              // REMOVED: Upload Button and "- OR -" text

              const SizedBox(height: 20),

              _buildTextFormField(
                controller: _nameController,
                label: 'Product Name',
                icon: Icons.label_outline,
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
              ),
              _buildTextFormField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description_outlined,
                maxLines: 3,
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description' : null,
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
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) return 'Invalid number';
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
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) return 'Invalid number';
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Update Product' : 'Save Product'),
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
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: validator,
      ),
    );
  }
}