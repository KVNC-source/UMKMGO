import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- IMPORTS ---
import 'package:umkmgo/providers/theme_provider.dart';
import 'package:umkmgo/providers/order_provider.dart';
import 'package:umkmgo/providers/auth_provider.dart';
import 'package:umkmgo/models/order.dart';
import 'package:umkmgo/views/shared/manage_address_page.dart';

// Import Seller Pages
// Make sure these file names match exactly what is in your lib/views/seller/ folder
import 'package:umkmgo/views/seller/seller_dashboard.dart';
import 'package:umkmgo/views/seller/manage_products_page.dart';
import 'package:umkmgo/views/seller/view_orders_page.dart';

// --- SUB-PAGES (EditProfile, PurchaseHistory, etc.) ---

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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.updateUserProfile(_nameController.text, _phoneController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui!')));
          Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Edit Profil'), elevation: 0.5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Center(child: CircleAvatar(radius: 50, child: Icon(Icons.person, size: 60))),
              const SizedBox(height: 30),
              _buildTextField('Nama Lengkap', _nameController, Icons.person),
              _buildTextField('Email', _emailController, Icons.email, readOnly: true),
              _buildTextField('Nomor Telepon', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan Perubahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool readOnly = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller, readOnly: readOnly, keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: readOnly, fillColor: readOnly ? Theme.of(context).cardColor : null),
        validator: (value) => (label != 'Nomor Telepon' && (value == null || value.isEmpty)) ? 'Bidang ini tidak boleh kosong' : null,
      ),
    );
  }
}

class PurchaseHistoryPage extends StatelessWidget {
  const PurchaseHistoryPage({super.key});
  String _formatRupiah(double amount) => 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pembelian')),
      body: userId == null ? const Center(child: Text('Silakan login.')) : StreamBuilder<List<Order>>(
        stream: orderProvider.getUserOrders(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) return const Center(child: Text('Belum ada pesanan.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15), elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    Text('Tanggal: ${_formatDate(order.date)}', style: TextStyle(color: Colors.grey.shade600)),
                    Text('Total: ${_formatRupiah(order.totalAmount)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    Text('Status: ${order.status}', style: TextStyle(color: Colors.green.shade700)),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Metode Pembayaran')), body: const Center(child: Text('Daftar kartu/rekening...')));
}
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Notifikasi')), body: const Center(child: Text('Pengaturan Notifikasi...')));
}
class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Bahasa')), body: const Center(child: Text('Pilihan Bahasa...')));
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final themeModel = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.userRole;

    List<Widget> profileSections = [];

    if (userRole == UserRole.seller) {
      profileSections.addAll(_buildShopManagementSection(context));
    }

    if (userRole == UserRole.buyer || userRole == UserRole.seller) {
      profileSections.addAll(_buildAccountSection(context));
    }

    profileSections.addAll(_buildSettingsSection(context, primaryColor, themeModel));
    profileSections.addAll(_buildSupportSection(context));

    return Scaffold(
      // App Bar provided by parent
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context, primaryColor, authProvider),

            const SizedBox(height: 30),
            ...profileSections,
            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () => authProvider.logout(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  child: const Text('Keluar'),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Color primaryColor, AuthProvider authProvider) {
    final userRole = authProvider.userRole;
    final userEmail = authProvider.currentUser?.email ?? 'No Email';
    final String userName = authProvider.currentUser?.name ?? ((userRole == UserRole.seller) ? 'Akun Penjual' : 'Akun Pembeli');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CircleAvatar(radius: 40, backgroundColor: Theme.of(context).cardColor, child: Icon((userRole == UserRole.seller) ? Icons.storefront : Icons.person, size: 50, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(userName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)), Text(userEmail, style: const TextStyle(fontSize: 14, color: Colors.deepOrange))]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity, height: 45,
            child: OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage())),
              style: OutlinedButton.styleFrom(foregroundColor: primaryColor, side: BorderSide(color: primaryColor, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Lihat/Edit Profil'),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildShopManagementSection(BuildContext context) {
    return [
      _buildSectionHeader(context, 'MANAJEMEN TOKO'),
      _buildListItem(context, Icons.storefront, 'Toko / Dashboard Saya', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerDashboardPage()))),
      _buildListItem(context, Icons.inventory_2_outlined, 'Manajemen Produk', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageProductsPage()))),
      _buildListItem(context, Icons.receipt_long, 'Lihat Pesanan', () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewOrdersPage()))),
    ];
  }

  List<Widget> _buildAccountSection(BuildContext context) {
    return [
      _buildSectionHeader(context, 'AKUN'),
      _buildListItem(context, Icons.history, 'Riwayat Pembelian', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseHistoryPage()))),
      _buildListItem(context, Icons.location_on_outlined, 'Daftar Alamat', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageAddressPage()))),
    ];
  }

  List<Widget> _buildSettingsSection(BuildContext context, Color primaryColor, ThemeProvider themeModel) {
    return [
      _buildSectionHeader(context, 'PENGATURAN'),
      _buildToggleItem(context, Icons.dark_mode_outlined, 'Mode Gelap', themeModel.isDarkMode, primaryColor, (v) => themeModel.setDarkMode(v)),
      _buildListItem(context, Icons.notifications_none, 'Notifikasi', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsPage()))),
      _buildListItem(context, Icons.language, 'Bahasa', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettingsPage()))),
    ];
  }

  List<Widget> _buildSupportSection(BuildContext context) {
    return [
      _buildSectionHeader(context, 'DUKUNGAN'),
      _buildListItem(context, Icons.help_outline, 'Pusat Bantuan', () {}),
      _buildListItem(context, Icons.engineering, 'Ketentuan Layanan', () {}),
    ];
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.labelMedium?.color, fontSize: 13)));
  }

  Widget _buildListItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant), title: Text(title), trailing: const Icon(Icons.chevron_right, color: Colors.grey), onTap: onTap);
  }

  Widget _buildToggleItem(BuildContext context, IconData icon, String title, bool value, Color activeColor, ValueChanged<bool> onChanged) {
    return ListTile(leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant), title: Text(title), trailing: Switch(value: value, onChanged: onChanged, activeColor: activeColor), onTap: () => onChanged(!value));
  }
}