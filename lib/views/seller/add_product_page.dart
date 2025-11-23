// lib/views/seller/add_product_page.dart

import 'dart:io'; // Needed for File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Needed for picking images
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

  // We no longer use a text controller for image URL input manually
  // But we keep track of the existing URL if editing
  String? _existingImageUrl;

  // File variable to store the picked image
  File? _pickedImageFile;

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

      // Store the existing URL if we are editing
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
    super.dispose();
  }

  // --- NEW: FUNCTION TO PICK IMAGE ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = File(pickedFile.path);
      });
    }
  }
  // -----------------------------------

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      // VALIDATION: Ensure an image is provided (either new pick or existing URL)
      if (_pickedImageFile == null && _existingImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick an image for the product.')),
        );
        return;
      }

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
        // 1. UPLOAD IMAGE IF A NEW ONE WAS PICKED
        String finalImageUrl = _existingImageUrl ?? ''; // Default to existing

        if (_pickedImageFile != null) {
          finalImageUrl = await productProvider.uploadProductImage(_pickedImageFile!);
        }

        // 2. SAVE PRODUCT DATA
        if (widget.productToEdit == null) {
          // CREATE
          final newProduct = Product(
            sellerId: currentUser.uid,
            name: _nameController.text,
            description: _descriptionController.text,
            imageUrl: finalImageUrl, // Use the uploaded URL
            price: double.tryParse(_priceController.text) ?? 0.0,
            category: _selectedCategory,
            shopName: currentShopName,
            stock: int.tryParse(_stockController.text) ?? 0,
          );
          await productProvider.addProduct(newProduct);
        } else {
          // UPDATE
          final updatedProduct = Product(
            id: widget.productToEdit!.id,
            sellerId: widget.productToEdit!.sellerId,
            name: _nameController.text,
            description: _descriptionController.text,
            imageUrl: finalImageUrl, // Use new URL if updated, else keep old
            price: double.tryParse(_priceController.text) ?? 0.0,
            category: _selectedCategory,
            shopName: currentShopName,
            stock: int.tryParse(_stockController.text) ?? 0,
          );
          await productProvider.updateProduct(widget.productToEdit!.id, updatedProduct);
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
              // --- IMAGE PICKER AREA ---
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _pickedImageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_pickedImageFile!, fit: BoxFit.cover),
                  )
                      : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]),
                      const SizedBox(height: 10),
                      Text('Tap to add image', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // -------------------------

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
                  child: Text(isEditing ? 'Update Product' : 'Upload Product'),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: validator,
      ),
    );
  }
}