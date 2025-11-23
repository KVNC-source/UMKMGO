import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umkmgo/providers/auth_provider.dart';
import 'package:umkmgo/views/shared/signup_page.dart'; // Normal Buyer Signup
import 'package:umkmgo/views/shared/seller_signup_page.dart'; // <<< NEW IMPORT

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() { _isLoading = true; });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.login(_emailController.text.trim(), _passwordController.text);
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Login Failed'),
            content: Text(e.toString().split('] ').last),
            actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.pop(ctx))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView( // Prevent overflow
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text('Welcome to UMKM Go', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login'),
                ),
              ),

              const SizedBox(height: 30),

              // --- REGISTRATION LINKS ---
              const Text("Don't have an account?"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage()));
                    },
                    child: const Text('Register as Buyer'),
                  ),
                  const Text("|", style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerSignupPage()));
                    },
                    child: const Text('Register as Seller'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}