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

    const Color primaryColor = Color(0xFF069E00);
    const Color accentColor = Color(0xFF4DDB4D);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UMKM Go',
      themeMode: themeModel.themeMode,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: accentColor,
          background: const Color(0xFFF7F9F9),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: accentColor,
          background: const Color(0xFF121212),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF056600),
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),

      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // 1. Show loading screen while fetching profile & role
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2. Check Login State & Role
          if (auth.isLoggedIn) {
            print("DEBUG: Main.dart - User Role is ${auth.userRole}");

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