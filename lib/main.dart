// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// --- PROVIDERS ---
import 'package:umkmgo/providers/cart_provider.dart';
import 'package:umkmgo/providers/theme_provider.dart';
import 'package:umkmgo/providers/order_provider.dart';
import 'package:umkmgo/providers/product_provider.dart';
import 'package:umkmgo/providers/wishlist_provider.dart';
import 'package:umkmgo/providers/auth_provider.dart';

// --- VIEWS ---
import 'package:umkmgo/views/shared/product_catalog_page.dart';
import 'package:umkmgo/views/shared/login_page.dart';
import 'package:umkmgo/views/admin/admin_dashboard.dart';
// Jika Anda punya halaman Buyer/Seller, impor juga, contoh:
// import 'package:umkmgo/views/shared/home_page_selector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => OrderProvider()),
        ChangeNotifierProvider(create: (context) => WishlistProvider()),
        ChangeNotifierProvider(create: (context) => ProductProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeProvider>(context);

    // --- WARNA BARU ANDA DITERAPKAN DI SINI ---
    const Color primaryColor = Color(0xFF4C763B); // <-- Warna hijau gelap yang Anda minta
    const Color accentColor = Color(0xFF7D9A6D);  // Warna aksen yang lebih terang dan serasi
    const Color darkErrorRed = Color(0xFFB00020);
    // ------------------------------------

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UMKM Go',
      themeMode: themeModel.themeMode,

      // --- TEMA TERANG (LIGHT THEME) ---
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor, // <-- Gunakan warna Anda
          primary: primaryColor,   // <-- Gunakan warna Anda
          secondary: accentColor,  // <-- Gunakan warna Anda
          background: const Color(0xFFF7F9F9),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor, // <-- Gunakan warna Anda
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor, // <-- Gunakan warna Anda
            foregroundColor: Colors.white,
          ),
        ),
      ),

      // --- TEMA GELAP (DARK THEME) ---
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,  // <-- Gunakan warna Anda
          primary: primaryColor,    // <-- Gunakan warna Anda
          secondary: accentColor,   // <-- Gunakan warna Anda
          background: const Color(0xFF121212),
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: primaryColor, // <-- Gunakan warna Anda
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),

      // Logika otentikasi Anda sudah benar, tidak perlu diubah.
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (auth.isLoggedIn) {
            switch (auth.userRole) {
              case UserRole.admin:
                return const AdminDashboard();
              case UserRole.seller:
                return const ProductCatalogPage();
              case UserRole.buyer:
              default:
                return const ProductCatalogPage();
            }
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
