import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // [NEW]

  // Seller specific controllers
  final _shopNameController = TextEditingController();
  final _shopDescController = TextEditingController();

  bool _isLoading = false;
  bool _isSellerSignup = false;

  // Password Visibility Toggles
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true; // [NEW]

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // [NEW]
    _shopNameController.dispose();
    _shopDescController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_isSellerSignup) {
        // --- SELLER SIGNUP FLOW ---
        await authProvider.signupSeller(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _phoneController.text.trim(),
          _shopNameController.text.trim(),
          _shopDescController.text.trim(),
        );

        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text("Permintaan Terkirim", style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text(
                "Akun Anda berhasil dibuat.\n\n"
                    "Karena Anda mendaftar sebagai Penjual, akun Anda memerlukan persetujuan Admin sebelum dapat digunakan untuk berjualan.\n\n"
                    "Silakan tunggu persetujuan Admin.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Mengerti"),
                )
              ],
            ),
          );

          await authProvider.logout();

          if (mounted) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false
            );
          }
        }
      } else {
        // --- BUYER SIGNUP FLOW ---
        await authProvider.signup(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _phoneController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal Mendaftar: ${e.toString().replaceAll('Exception:', '')}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- HEADER ---
                  Icon(Icons.app_registration, size: 60, color: primaryColor),
                  const SizedBox(height: 10),
                  Text(
                    "Buat Akun Baru",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _isSellerSignup
                        ? "Daftar untuk mulai berjualan"
                        : "Daftar untuk mulai belanja",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 30),

                  // --- ROLE TOGGLE ---
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        _buildToggleButton("Pembeli", !_isSellerSignup),
                        _buildToggleButton("Penjual", _isSellerSignup),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- COMMON FIELDS ---
                  _buildTextField(
                    controller: _nameController,
                    label: "Nama Lengkap",
                    icon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? "Nama wajib diisi" : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => !v!.contains('@') ? "Email tidak valid" : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: "Nomor Telepon",
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.length < 10 ? "Nomor tidak valid" : null,
                  ),

                  // --- SELLER FIELDS ---
                  AnimatedCrossFade(
                    firstChild: Container(),
                    secondChild: Column(
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: primaryColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Akun penjual memerlukan persetujuan Admin sebelum aktif.",
                                  style: TextStyle(fontSize: 12, color: primaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _shopNameController,
                          label: "Nama Toko",
                          icon: Icons.storefront_outlined,
                          validator: (v) => (_isSellerSignup && v!.isEmpty) ? "Nama Toko wajib diisi" : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _shopDescController,
                          label: "Deskripsi Toko",
                          icon: Icons.description_outlined,
                          maxLines: 2,
                          validator: (v) => (_isSellerSignup && v!.isEmpty) ? "Deskripsi wajib diisi" : null,
                        ),
                      ],
                    ),
                    crossFadeState: _isSellerSignup ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),

                  const SizedBox(height: 16),

                  // --- PASSWORD ---
                  _buildTextField(
                    controller: _passwordController,
                    label: "Password",
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    isPassword: true,
                    onPasswordToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    validator: (v) => v!.length < 6 ? "Password minimal 6 karakter" : null,
                  ),

                  const SizedBox(height: 16),

                  // --- CONFIRM PASSWORD [NEW] ---
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: "Ulangi Password",
                    icon: Icons.lock_reset_outlined,
                    obscureText: _obscureConfirmPassword,
                    isPassword: true,
                    onPasswordToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Ulangi password wajib diisi";
                      if (v != _passwordController.text) return "Password tidak sama";
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  // --- SUBMIT ---
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                        _isSellerSignup ? "Ajukan Akun Penjual" : "Daftar Akun",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- FOOTER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Sudah punya akun? ", style: TextStyle(color: Colors.grey[600])),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                        },
                        child: Text(
                          "Masuk",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildToggleButton(String text, bool isActive) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isSellerSignup = (text == "Penjual");
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, spreadRadius: 1)]
                : [],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? primaryColor : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isPassword = false,
    int maxLines = 1,
    String? Function(String?)? validator,
    VoidCallback? onPasswordToggle, // [NEW] Callback for toggle
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22, color: Colors.grey[500]),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.grey[500],
          ),
          onPressed: onPasswordToggle,
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}