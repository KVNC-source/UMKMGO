import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- IMPORTS ---
import 'package:umkmgo/providers/theme_provider.dart';
import 'package:umkmgo/providers/order_provider.dart';
import 'package:umkmgo/providers/auth_provider.dart';
import 'package:umkmgo/models/order.dart';
import 'package:umkmgo/views/shared/manage_address_page.dart';

// Import Seller Pages
import 'package:umkmgo/views/seller/seller_dashboard.dart';
import 'package:umkmgo/views/seller/manage_products_page.dart';
import 'package:umkmgo/views/seller/view_orders_page.dart';

// --- SUB-PAGES (EditProfile, PurchaseHistory) ---
// (These classes remain unchanged, included for completeness)

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

    return Scaffold(
      // Use a slightly different background color to make the Cards pop
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0), // Consistent padding for the whole page
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER (Wrapped in a Card for proportion)
              _buildProfileHeader(context, primaryColor, authProvider),

              const SizedBox(height: 24),

              // 2. SECTIONS (Each section is a Card group)
              if (userRole == UserRole.seller)
                _buildSectionGroup(
                    context,
                    'MANAJEMEN TOKO',
                    [
                      _buildListItem(context, Icons.storefront, 'Dashboard Saya', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerDashboardPage()))),
                      _buildListItem(context, Icons.inventory_2_outlined, 'Manajemen Produk', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageProductsPage()))),
                      _buildListItem(context, Icons.receipt_long, 'Lihat Pesanan', () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewOrdersPage()))),
                    ]
                ),

              if (userRole == UserRole.buyer || userRole == UserRole.seller)
                _buildSectionGroup(
                    context,
                    'AKUN',
                    [
                      _buildListItem(context, Icons.history, 'Riwayat Pembelian', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseHistoryPage()))),
                      _buildListItem(context, Icons.location_on_outlined, 'Daftar Alamat', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageAddressPage()))),
                    ]
                ),

              _buildSectionGroup(
                  context,
                  'PENGATURAN',
                  [
                    _buildToggleItem(context, Icons.dark_mode_outlined, 'Mode Gelap', themeModel.isDarkMode, primaryColor, (v) => themeModel.setDarkMode(v)),
                  ]
              ),

              const SizedBox(height: 20),

              // 3. LOGOUT BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => authProvider.logout(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red.shade200)
                      )
                  ),
                  child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Refined Header Component
  Widget _buildProfileHeader(BuildContext context, Color primaryColor, AuthProvider authProvider) {
    final userRole = authProvider.userRole;
    final userEmail = authProvider.currentUser?.email ?? 'No Email';
    final String userName = authProvider.currentUser?.name ?? ((userRole == UserRole.seller) ? 'Akun Penjual' : 'Akun Pembeli');

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 35, // Slightly smaller to balance with text
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                      (userRole == UserRole.seller) ? Icons.storefront : Icons.person,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary
                  ),
                ),
                const SizedBox(width: 16),
                Expanded( // Prevents overflow
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 4),
                        Text(userEmail, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4)
                          ),
                          child: Text(
                            userRole == UserRole.seller ? 'Seller' : 'Buyer',
                            style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold),
                          ),
                        )
                      ]
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage())),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Refined Section Group Component
  Widget _buildSectionGroup(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 12,
                  letterSpacing: 1.0
              )
          ),
        ),
        Card(
          elevation: 0, // Flat card style
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200) // Subtle border
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8)
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant)
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Added vertical padding
    );
  }

  Widget _buildToggleItem(BuildContext context, IconData icon, String title, bool value, Color activeColor, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8)
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant)
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: activeColor),
      onTap: () => onChanged(!value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}