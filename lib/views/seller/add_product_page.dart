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
  late TextEditingController _imageUrlController;
  String? _existingImageUrl;
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

  String _convertDriveUrl(String url) {
    final RegExp regExp = RegExp(r'\/file\/d\/([a-zA-Z0-9_-]+)\/?');
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return 'https://drive.google.com/uc?export=view&id=${match.group(1)}';
    }
    return url;
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        // ... (existing save logic same as before, updated URL conversion) ...
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
        if (currentUser == null) throw Exception("Not logged in");

        String finalImageUrl = _imageUrlController.text.isNotEmpty ? _convertDriveUrl(_imageUrlController.text) : (_existingImageUrl ?? '');
        if (finalImageUrl.isEmpty) throw Exception("Image URL required");

        final newProduct = Product(
          id: widget.productToEdit?.id ?? '',
          sellerId: widget.productToEdit?.sellerId ?? currentUser.uid,
          name: _nameController.text,
          description: _descriptionController.text,
          imageUrl: finalImageUrl,
          price: double.tryParse(_priceController.text) ?? 0.0,
          category: _selectedCategory,
          shopName: currentUser.shopName.isNotEmpty ? currentUser.shopName : 'My Shop',
          stock: int.tryParse(_stockController.text) ?? 0,
        );

        if (widget.productToEdit == null) {
          await productProvider.addProduct(newProduct);
        } else {
          await productProvider.updateProduct(widget.productToEdit!.id, newProduct);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imagePreview;
    if (_imageUrlController.text.isNotEmpty) {
      imagePreview = NetworkImage(_convertDriveUrl(_imageUrlController.text));
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      imagePreview = NetworkImage(_existingImageUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.productToEdit != null ? 'Edit Produk' : 'Tambah Produk'), centerTitle: true),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 180, width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor, // Dark mode fix
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: imagePreview != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image(image: imagePreview, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50)))
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, size: 50, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(height: 8), Text('Preview Gambar', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))]),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(_imageUrlController, 'Link Gambar', Icons.link, onChanged: (v) => setState(() {})),
              const SizedBox(height: 24),
              const Text('Informasi Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Nama Produk', Icons.label_outline),
              _buildTextField(_descriptionController, 'Deskripsi', Icons.description_outlined, maxLines: 3),
              Row(children: [Expanded(child: _buildTextField(_priceController, 'Harga', Icons.attach_money, keyboardType: TextInputType.number)), const SizedBox(width: 16), Expanded(child: _buildTextField(_stockController, 'Stok', Icons.inventory_2_outlined, keyboardType: TextInputType.number))]),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Kategori', prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true, fillColor: Theme.of(context).cardColor, // Dark mode fix
                ),
                dropdownColor: Theme.of(context).cardColor, // Dark mode fix
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: _saveForm, style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text, void Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller, maxLines: maxLines, keyboardType: keyboardType, onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icon, size: 22),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true, fillColor: Theme.of(context).cardColor, // Dark mode fix
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Wajib diisi' : null,
      ),
    );
  }
}