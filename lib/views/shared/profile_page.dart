import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- CORRECTED IMPORTS ---
import 'package:umkmgo/providers/theme_provider.dart';
import 'package:umkmgo/providers/order_provider.dart';
import 'package:umkmgo/views/shared/login_page.dart';
// -------------------------

// --- BUYER PAGES (Functional Implementations) ---

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController(
    text: 'Siti Aminah',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'siti.aminah@email.com',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '0812-3456-7890',
  );
  final _formKey = GlobalKey<FormState>();

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile saved! Name: ${_nameController.text}')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), elevation: 0.5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 60),
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField('Nama Lengkap', _nameController, Icons.person),
              _buildTextField(
                'Email',
                _emailController,
                Icons.email,
                readOnly: true,
              ),
              _buildTextField(
                'Nomor Telepon',
                _phoneController,
                Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Simpan Perubahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: readOnly,
          fillColor: readOnly ? Theme.of(context).cardColor : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Bidang ini tidak boleh kosong';
          }
          return null;
        },
      ),
    );
  }
}

class PurchaseHistoryPage extends StatelessWidget {
  const PurchaseHistoryPage({super.key});

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final orderModel = Provider.of<OrderProvider>(context);
    final orders = orderModel.pastOrders;

    return Scaffold(
      appBar: AppBar(title: const Text('Status Pesanan')),
      body: orders.isEmpty
          ? Center(
              child: Text(
                'Anda belum memiliki riwayat pesanan.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.orderId,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                order.status,
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          'Tanggal: ${_formatDate(order.date)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Total: ${_formatRupiah(order.totalAmount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${order.items.length} jenis barang dari ${order.items.map((e) => e.shopName).toSet().length} toko',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: const Center(
        child: Text('List of saved cards/accounts goes here.'),
      ),
    );
  }
}

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: const Center(
        child: Text('Toggles for various notification types.'),
      ),
    );
  }
}

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language Settings')),
      body: const Center(child: Text('Option to change app language.')),
    );
  }
}
// ----------------------------------------------------

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
    final currentUser = FirebaseAuth.instance.currentUser;

    List<Widget> profileSections = [];

    // Account section for all users
    profileSections.addAll(_buildAccountSection(context));
    profileSections.addAll(
      _buildSettingsSection(context, primaryColor, themeModel),
    );

    return Scaffold(
      // AppBar is provided by ProductCatalogPage
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context, primaryColor, currentUser),
                  const SizedBox(height: 30),
                  ...profileSections,
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Log Out'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    Color primaryColor,
    User? currentUser,
  ) {
    final userEmail = currentUser?.email ?? 'No Email';
    final userName = userEmail.split('@')[0];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Icon(Icons.person, size: 50, color: primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('View/Edit Profile'),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAccountSection(BuildContext context) {
    return [
      _buildSectionHeader(context, 'PESANAN SAYA'),
      _buildListItem(
        context,
        Icons.shopping_bag_outlined,
        'Status Pesanan',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PurchaseHistoryPage()),
        ),
      ),
      _buildListItem(
        context,
        Icons.history,
        'Riwayat Pembelian',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PurchaseHistoryPage()),
        ),
      ),
      _buildListItem(context, Icons.credit_card, 'Metode Pembayaran', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentMethodsPage()),
        );
      }),
    ];
  }

  List<Widget> _buildSettingsSection(
    BuildContext context,
    Color primaryColor,
    ThemeProvider themeModel,
  ) {
    return [
      _buildSectionHeader(context, 'SETTINGS'),
      _buildToggleItem(
        context,
        Icons.dark_mode_outlined,
        'Dark Mode',
        themeModel.isDarkMode,
        primaryColor,
        (newValue) {
          themeModel.setDarkMode(newValue);
          _showSnackbar(
            context,
            'Dark Mode: ${newValue ? 'Enabled' : 'Disabled'}',
          );
        },
      ),
      _buildListItem(context, Icons.notifications_none, 'Notifications', () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationSettingsPage(),
          ),
        );
      }),
      _buildListItem(context, Icons.language, 'Language', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LanguageSettingsPage()),
        );
      }),
    ];
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(
            context,
          ).textTheme.labelMedium?.color, // <<< FIX: Theme-aware color
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildToggleItem(
    BuildContext context,
    IconData icon,
    String title,
    bool value,
    Color activeColor,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      ),
      onTap: () {
        onChanged(!value);
      },
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
