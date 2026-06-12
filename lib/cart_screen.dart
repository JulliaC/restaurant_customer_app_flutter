import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../services/cart_provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isPlacingOrder = false;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final service = context.read<FirebaseService>();

    setState(() => _isPlacingOrder = true);

    try {
      final order = Order(
        id: const Uuid().v4(),
        tableNumber: cart.tableNumber,
        items: cart.items.toList(),
        createdAt: DateTime.now(),
        customerNote: _noteController.text.trim(),
      );

      final orderId = await service.placeOrder(order);
      cart.setPendingOrder(orderId);
      cart.clearOrder();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppTheme.card,
                    title: Text('Clear order',
                        style: Theme.of(context).textTheme.titleLarge),
                    content: Text('Remove all items?',
                        style: Theme.of(context).textTheme.bodyMedium),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () {
                          cart.clearOrder();
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Clear',
                            style: TextStyle(color: AppTheme.error)),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Clear',
                  style: TextStyle(color: AppTheme.error, fontSize: 13)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: AppTheme.divider, height: 1,
                    ),
                    itemBuilder: (_, i) {
                      final cartItem = cart.items[i];
                      return _CartRow(cartItem: cartItem);
                    },
                  ),
                ),

                // ── Note & summary ────────────────────────────────────────
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16, 16, 16,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(
                      top: BorderSide(color: AppTheme.divider),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Note
                      TextField(
                        controller: _noteController,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Any notes? (allergies, preferences…)',
                          hintStyle: Theme.of(context).textTheme.bodyMedium,
                          filled: true,
                          fillColor: AppTheme.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Total row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total',
                              style: Theme.of(context).textTheme.titleLarge),
                          Text(
                            '${cart.totalPrice.toStringAsFixed(2)} lei',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Place order button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isPlacingOrder
                              ? null
                              : () => _placeOrder(context),
                          child: _isPlacingOrder
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.send_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Send order to kitchen  •  Table ${cart.tableNumber}',
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final cartItem;
  const _CartRow({required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.item.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${cartItem.item.price.toStringAsFixed(2)} lei each',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Qty control
          Row(
            children: [
              _SmBtn(
                icon: Icons.remove,
                onTap: () => cart.remove(cartItem.item),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${cartItem.quantity}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _SmBtn(
                icon: Icons.add,
                onTap: () => cart.add(cartItem.item),
              ),
            ],
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 70,
            child: Text(
              '${cartItem.subtotal.toStringAsFixed(2)} lei',
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Icon(icon, size: 14, color: AppTheme.accent),
    ),
  );
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shopping_bag_outlined,
            color: AppTheme.textSecondary, size: 64),
        const SizedBox(height: 16),
        Text('Your order is empty',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Add items from the menu',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to menu'),
        ),
      ],
    ),
  );
}
