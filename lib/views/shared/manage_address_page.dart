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
          title: const Text('Tambah Alamat Baru'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(_labelController, 'Label (cth: Rumah, Kantor)'),
                  _buildTextField(_streetController, 'Jalan & Nomor Rumah'),
                  _buildTextField(_cityController, 'Kota & Kode Pos'),
                  _buildTextField(_phoneController, 'Nomor Telepon', TextInputType.phone),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              child: const Text('Simpan'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // FIX: Wrap the 4 strings into a SINGLE Map object
                  final addressData = {
                    'label': _labelController.text,
                    'street': _streetController.text,
                    'city': _cityController.text,
                    'phone': _phoneController.text,
                  };

                  // Call provider with the Map
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

  Widget _buildTextField(TextEditingController controller, String label, [TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        validator: (value) => (value == null || value.isEmpty) ? '$label wajib diisi' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final addresses = authProvider.currentUser?.addresses ?? [];

        return Scaffold(
          appBar: AppBar(title: const Text('Daftar Alamat')),
          body: addresses.isEmpty
              ? const Center(child: Text('Belum ada alamat.', style: TextStyle(fontSize: 16, color: Colors.grey)))
              : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: Icon(
                    address.label.toLowerCase() == 'rumah' ? Icons.home : Icons.business,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(address.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${address.street}, ${address.city}\n${address.phone}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hapus Alamat?'),
                          content: Text('Anda yakin ingin menghapus alamat "${address.label}"?'),
                          actions: [
                            TextButton(
                              child: const Text('Batal'),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
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
                    },
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddAddressDialog,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}