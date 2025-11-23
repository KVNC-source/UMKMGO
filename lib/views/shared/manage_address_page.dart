import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umkmgo/providers/auth_provider.dart';
import 'package:umkmgo/models/address.dart';

class ManageAddressPage extends StatefulWidget {
  const ManageAddressPage({super.key});

  @override
  State<ManageAddressPage> createState() => _ManageAddressPageState();
}

class _ManageAddressPageState extends State<ManageAddressPage> {
  final _labelController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showAddAddressDialog() {
    _formKey.currentState?.reset();
    _labelController.clear();
    _streetController.clear();
    _cityController.clear();
    _phoneController.clear();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tambah Alamat Baru', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(_labelController, 'Label', Icons.label_outline),
                  _buildTextField(_streetController, 'Jalan & Nomor', Icons.map_outlined),
                  _buildTextField(_cityController, 'Kota', Icons.location_city_outlined),
                  _buildTextField(_phoneController, 'No. Telepon', Icons.phone_outlined, TextInputType.phone),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(ctx).pop()),
            FilledButton(
              child: const Text('Simpan'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final addressData = {
                    'label': _labelController.text,
                    'street': _streetController.text,
                    'city': _cityController.text,
                    'phone': _phoneController.text,
                  };
                  Provider.of<AuthProvider>(context, listen: false).addAddress(addressData);
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, [TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor, // Adapt to theme
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Wajib diisi' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final addresses = authProvider.userAddresses;

        return Scaffold(
          appBar: AppBar(title: const Text('Daftar Alamat'), centerTitle: true),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Dark mode fix
          body: addresses.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off_outlined, size: 80, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text('Belum ada alamat tersimpan.', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: addresses.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final address = addresses[index];
              final isHome = address.label.toLowerCase().contains('rumah') || address.label.toLowerCase().contains('home');

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, // Dark mode fix
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(isHome ? Icons.home_rounded : Icons.business_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(address.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('${address.street}, ${address.city}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Icon(Icons.phone, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(address.phone, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ]),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _showDeleteDialog(context, authProvider, address),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddAddressDialog,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, AuthProvider authProvider, Address address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Alamat?'),
        content: Text('Anda yakin ingin menghapus alamat "${address.label}"?'),
        actions: [
          TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onPressed: () {
              authProvider.deleteAddress(address.id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}