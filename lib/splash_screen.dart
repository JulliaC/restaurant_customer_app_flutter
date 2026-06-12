import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to error if opened without a QR link
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/error');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: Colors.black,
                size: 52,
              ),
            ).animate().scale(
              begin: const Offset(0.5, 0.5),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),
            const SizedBox(height: 28),
            Text(
              'Scan & Order',
              style: Theme.of(context).textTheme.displayLarge,
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
            const SizedBox(height: 8),
            Text(
              'Scan a table QR code to get started',
              style: Theme.of(context).textTheme.bodyMedium,
            ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
