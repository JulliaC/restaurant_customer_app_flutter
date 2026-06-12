/// This screen is for the restaurant owner/admin — not shown to customers.
/// Use it to generate and print QR codes for each table.
/// 
/// Each QR encodes: https://yourdomain.com/menu?table=N
/// When a customer scans it, the app launches and knows it's Table N.

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  // ⚠️ Replace with your actual domain / app scheme
  static const String baseUrl = 'https://yourdomain.com/menu';
  
  int _tableCount = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Codes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Tables: ', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _tableCount.toDouble(),
                    min: 1, max: 50,
                    divisions: 49,
                    activeColor: AppTheme.accent,
                    label: '$_tableCount',
                    onChanged: (v) => setState(() => _tableCount = v.round()),
                  ),
                ),
                Text('$_tableCount'),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: _tableCount,
              itemBuilder: (_, i) {
                final table = i + 1;
                final url = '$baseUrl?table=$table';
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        'Table $table',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: QrImageView(
                          data: url,
                          version: QrVersions.auto,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan to order',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
