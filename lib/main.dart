import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'theme/app_theme.dart';
import 'services/cart_provider.dart';
import 'services/firebase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/order_status_screen.dart';
import 'screens/table_error_screen.dart';

// ─── Deep link / QR URL format ────────────────────────────────────────────────
// The QR code on each table should encode a URL like:
//   https://yourdomain.com/menu?table=5
// OR for Android app links / iOS universal links use:
//   restaurantapp://menu?table=5
//
// The app parses the `table` query parameter and stores it in CartProvider.
// Every order sent to Firebase includes { tableNumber: 5 } so the kitchen
// knows exactly which table placed the order.
// ──────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatefulWidget {
  const RestaurantApp({super.key});

  @override
  State<RestaurantApp> createState() => _RestaurantAppState();
}

class _RestaurantAppState extends State<RestaurantApp> {
  final _appLinks = AppLinks();
  final _cartProvider = CartProvider();
  final _firebaseService = FirebaseService();

  // The initial route — set after we check the launch link
  String _initialRoute = '/splash';
  int _initialTable = 0;

  @override
  void initState() {
    super.initState();
    _handleInitialLink();
    _listenForLinks();
  }

  Future<void> _handleInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _processLink(uri);
      }
    } catch (_) {}
  }

  void _listenForLinks() {
    _appLinks.uriLinkStream.listen((uri) {
      _processLink(uri);
    });
  }

  void _processLink(Uri uri) {
    // Works with both:
    //   https://yourdomain.com/menu?table=5
    //   restaurantapp://menu?table=5
    final tableParam = uri.queryParameters['table'];
    if (tableParam != null) {
      final tableNumber = int.tryParse(tableParam);
      if (tableNumber != null && tableNumber > 0) {
        _cartProvider.setTable(tableNumber);
        setState(() {
          _initialRoute = '/menu';
          _initialTable = tableNumber;
        });
        return;
      }
    }
    // No valid table in link
    setState(() => _initialRoute = '/error');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _cartProvider),
        Provider.value(value: _firebaseService),
      ],
      child: MaterialApp(
        title: 'Order',
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        initialRoute: _initialRoute,
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/menu':   (_) => MenuScreen(tableNumber: _initialTable),
          '/cart':   (_) => const CartScreen(),
          '/status': (_) => const OrderStatusScreen(),
          '/error':  (_) => const TableErrorScreen(),
        },
      ),
    );
  }
}
