import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// --- IMPORTS FOR DECOUPLED MODELS AND PROVIDERS ---
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/auth_provider.dart'; // <<< 1. NEW IMPORT

// --- IMPORT SCREENS ---
import 'views/shared/product_catalog_page.dart';
import 'views/shared/login_page.dart'; // <`<< 2. NEW IMPORT
import 'views/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        // Registering all state managers (ChangeNotifiers)
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => OrderProvider()),
        ChangeNotifierProvider(create: (context) => WishlistProvider()),
        ChangeNotifierProvider(create: (context) => ProductProvider()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ), // <<< 3. ADD PROVIDER
      ],
      child: const MyApp(),
    ),
  );
}

/// Main App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeProvider>(context);
    const Color primaryGreen = Color(0xFF00D100);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Discover Local Products',

      themeMode: themeModel.themeMode,

      // Define Light Theme (omitted for brevity)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: primaryGreen,
          secondary: primaryGreen,
        ),
      ),

      // Define Dark Theme (omitted for brevity)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: primaryGreen,
          secondary: primaryGreen,
          surface: Color(0xFF121212),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),

      // --- 4. CREATE THE "AUTH GATE" ---
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (!auth.isLoggedIn) {
            return const LoginPage();
          }

          if (auth.userRole == UserRole.admin) {
            return const AdminDashboard();
          }

          return const ProductCatalogPage();
        },
      ),
    );
  }
}
