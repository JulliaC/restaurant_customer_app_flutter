import 'package:flutter/material.dart';
import 'package:restaurant_app_flutter/see_order_page.dart';
import 'home_page.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCGZoSVkFGCfFfNkm1X7sWOcyiJ3JGhUmE",
      authDomain: "restaurant-app-3d392.firebaseapp.com",
      projectId: "restaurant-app-3d392",
      storageBucket: "restaurant-app-3d392.appspot.com",
      messagingSenderId: "899479304941",
      appId: "1:899479304941:web:7343cc3ade40abea666ae4",
      measurementId: "G-YDYG432H00",
    ),
  );

  // Read table number from URL, e.g. https://site.com/?table=7
  final int tableNumber =
      int.tryParse(Uri.base.queryParameters['table'] ?? '') ?? 1;

  runApp(MyApp(tableNumber: tableNumber));
}

class MyApp extends StatelessWidget {
  final int tableNumber;
  const MyApp({super.key, required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Keep your HomePage as the start
      home: HomePage(tableNumber: tableNumber),

      // Keep your routes map style, but pass tableNumber via arguments
      routes: {
        '/seeOrder': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final int t = (args is int) ? args : tableNumber;
          return SeeOrderPage(tableNumber: t);
        },
      },
    );
  }
}
