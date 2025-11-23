import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umkmgo/providers/auth_provider.dart';

class SellerSignupPage extends StatefulWidget {
  const SellerSignupPage({super.key});

  @override
  State<SellerSignupPage> createState() => _SellerSignupPageState();
}

class _SellerSignupPageState extends State<SellerSignupPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopDescController = TextEditingController();

  bool _isLoading = false;

  void _handleSellerSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        // 1. Create the account and request (this auto-logs in)
        await authProvider.signupSeller(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          _phoneController.text.trim(),
          _shopNameController.text.trim(),
          _shopDescController.text.trim(),
        );

        // 2. CRITICAL FIX: Immediately log out so they don't enter the app
        await authProvider.logout();

        if (mounted) {
          // 3. Show success dialog
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Request Sent Successfully'),
              content: const Text(
                'Your seller account has been created and is pending approval.\n\n'
                    'Please wait for an Admin to approve your request before logging in.',
              ),
              actions: [
                TextButton(
                  child: const Text('Back to Login'),
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.of(context).pop(); // Go back to Login Page
                  },
                )
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Registration Failed'),
              content: Text(e.toString().split('] ').last),
              actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.pop(ctx))],
            ),
          );
        }
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); _emailController.dispose(); _phoneController.dispose();
    _passwordController.dispose(); _confirmPasswordController.dispose();
    _shopNameController.dispose(); _shopDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register as Seller')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Seller Application',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              const Text("Personal Information", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person),
              _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone, inputType: TextInputType.phone),
              _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email, inputType: TextInputType.emailAddress),

              const SizedBox(height: 20),
              const Text("Shop Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildTextField(controller: _shopNameController, label: 'Shop Name', icon: Icons.store),
              _buildTextField(controller: _shopDescController, label: 'Business Description / Credentials', icon: Icons.description, maxLines: 3),

              const SizedBox(height: 20),
              const Text("Security", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildPasswordField(_passwordController, 'Password'),
              _buildPasswordField(_confirmPasswordController, 'Confirm Password', isConfirm: true),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSellerSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller, keyboardType: inputType, maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: Icon(icon)),
        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, {bool isConfirm = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller, obscureText: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock)),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          if (value.length < 6) return 'Min 6 characters';
          if (isConfirm && value != _passwordController.text) return 'Passwords do not match';
          return null;
        },
      ),
    );
  }
}