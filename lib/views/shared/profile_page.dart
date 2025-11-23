import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umkmgo/providers/theme_provider.dart';
import 'package:umkmgo/providers/order_provider.dart';
import 'package:umkmgo/providers/auth_provider.dart';
import 'package:umkmgo/models/order.dart';
import 'package:umkmgo/views/shared/manage_address_page.dart';
import 'package:umkmgo/views/seller/seller_dashboard.dart';
import 'package:umkmgo/views/seller/manage_products_page.dart';
import 'package:umkmgo/views/seller/view_orders_page.dart';

// --- EDIT PROFILE PAGE ---
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    _nameController = TextEditingController(text: currentUser?.name ?? '');
    _emailController = TextEditingController(text: currentUser?.email ?? 'No Email');
    _phoneController = TextEditingController(text: currentUser?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<AuthProvider>(context, listen: false)
            .updateUserProfile(_nameController.text, _phoneController.text);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui!')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.primary),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildTextField('Nama Lengkap', _nameController, Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField('Email', _emailController, Icons.email_outlined, readOnly: true),
              const SizedBox(height: 16),
              _buildTextField('Nomor Telepon', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool readOnly = false, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: readOnly
            ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5)
            : Theme.of(context).cardColor,
      ),
      validator: (value) => (label != 'Nomor Telepon' && (value == null || value.isEmpty)) ? 'Bidang ini tidak boleh kosong' : null,
    );
  }
}

// --- PURCHASE HISTORY PAGE ---
class PurchaseHistoryPage extends StatelessWidget {
  const PurchaseHistoryPage({super.key});
  String _formatRupiah(double amount) => 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'shipping': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pembelian'), centerTitle: true),
      body: userId == null
          ? const Center(child: Text('Silakan login.'))
          : StreamBuilder<List<Order>>(
        stream: Provider.of<OrderProvider>(context, listen: false).getUserOrders(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('Belum ada pesanan.', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              final statusColor = _getStatusColor(order.status);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order ID', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            Text('#${order.orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(order.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tanggal', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            Text(_formatDate(order.date), style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        Text(_formatRupiah(order.totalAmount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- MAIN PROFILE PAGE ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.userRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(context, authProvider),
            const SizedBox(height: 30),

            if (userRole == UserRole.seller)
              _buildSectionGroup(context, 'MANAJEMEN TOKO', [
                _buildListItem(context, Icons.dashboard_outlined, 'Dashboard Toko', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerDashboardPage()))),
                _buildListItem(context, Icons.inventory_2_outlined, 'Produk Saya', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageProductsPage()))),
                _buildListItem(context, Icons.receipt_long_outlined, 'Pesanan Masuk', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewOrdersPage()))),
              ]),

            if (userRole == UserRole.buyer || userRole == UserRole.seller)
              _buildSectionGroup(context, 'AKTIVITAS SAYA', [
                _buildListItem(context, Icons.shopping_bag_outlined, 'Riwayat Pembelian', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseHistoryPage()))),
                _buildListItem(context, Icons.location_on_outlined, 'Daftar Alamat', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageAddressPage()))),
              ]),

            _buildSectionGroup(context, 'PENGATURAN', [
              _buildToggleItem(
                  context,
                  Icons.dark_mode_outlined,
                  'Mode Gelap',
                  themeModel.isDarkMode,
                      (v) {
                    // 1. Change the theme first
                    themeModel.setDarkMode(v);

                    // 2. Show popup/notification ONLY if turning ON (v == true)
                    if (v) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(child: Text('Mode Gelap masih dalam pengembangan (WIP).')),
                            ],
                          ),
                          backgroundColor: Colors.orange.shade800,
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  }
              ),
            ]),

            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => authProvider.logout(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade200),
                  foregroundColor: Colors.red.shade400,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AuthProvider authProvider) {
    final userRole = authProvider.userRole;
    final userName = authProvider.currentUser?.name ?? ((userRole == UserRole.seller) ? 'Akun Penjual' : 'Akun Pembeli');
    final userEmail = authProvider.currentUser?.email ?? 'No Email';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Theme.of(context).cardColor,
            child: Icon((userRole == UserRole.seller) ? Icons.storefront : Icons.person, size: 36, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
              const SizedBox(height: 4),
              Text(userEmail, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                child: Text(userRole == UserRole.seller ? 'Penjual Terverifikasi' : 'Member', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              )
            ]),
          ),
          IconButton(
            style: IconButton.styleFrom(backgroundColor: Theme.of(context).cardColor),
            icon: Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.primary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
          )
        ],
      ),
    );
  }

  Widget _buildSectionGroup(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary)
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildToggleItem(BuildContext context, IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      onTap: () => onChanged(!value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary)
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}