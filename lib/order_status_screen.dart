import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/order.dart';
import '../services/cart_provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final service = context.read<FirebaseService>();
    final orderId = cart.pendingOrderId;

    if (orderId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long,
                  color: AppTheme.textSecondary, size: 56),
              const SizedBox(height: 16),
              Text('No active order',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/menu'),
                child: const Text('Back to menu'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order status'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/menu'),
            child: const Text('Menu',
                style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
      body: StreamBuilder<OrderStatus>(
        stream: service.orderStatusStream(orderId),
        builder: (context, snap) {
          final status = snap.data ?? OrderStatus.pending;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status icon
                _StatusIcon(status: status)
                    .animate(key: ValueKey(status))
                    .scale(duration: 400.ms, curve: Curves.elasticOut),

                const SizedBox(height: 24),

                Text(
                  status.label,
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(),

                const SizedBox(height: 8),
                Text(
                  'Table ${cart.tableNumber}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 40),

                // Progress steps
                _StatusStepper(currentStatus: status),

                const SizedBox(height: 40),

                if (status == OrderStatus.ready)
                  _ReadyBanner()
                      .animate()
                      .fadeIn()
                      .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // Order more button
                if (status != OrderStatus.served)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      side: const BorderSide(color: AppTheme.accent),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/menu'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add more items'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final OrderStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      OrderStatus.pending    => (Icons.hourglass_top_rounded, AppTheme.textSecondary),
      OrderStatus.confirmed  => (Icons.check_circle_outline, AppTheme.accent),
      OrderStatus.preparing  => (Icons.outdoor_grill_outlined, AppTheme.accentLight),
      OrderStatus.ready      => (Icons.room_service_outlined, AppTheme.success),
      OrderStatus.served     => (Icons.sentiment_very_satisfied, AppTheme.success),
    };

    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 48),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  final OrderStatus currentStatus;
  const _StatusStepper({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (OrderStatus.pending, 'Received', Icons.receipt),
      (OrderStatus.confirmed, 'Confirmed', Icons.check),
      (OrderStatus.preparing, 'Preparing', Icons.outdoor_grill),
      (OrderStatus.ready, 'Ready', Icons.room_service),
      (OrderStatus.served, 'Served', Icons.sentiment_satisfied),
    ];

    final currentIndex = OrderStatus.values.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final (_, label, icon) = entry.value;
          final isDone = idx <= currentIndex;
          final isCurrent = idx == currentIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.accent
                        : AppTheme.card,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isDone ? Colors.black : AppTheme.textSecondary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isDone
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Now',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReadyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.success.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.success.withOpacity(0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.notifications_active,
            color: AppTheme.success, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your order is ready!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.success,
                ),
              ),
              Text(
                'A member of staff will bring it to your table shortly.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
