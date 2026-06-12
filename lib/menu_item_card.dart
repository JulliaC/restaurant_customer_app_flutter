import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../services/cart_provider.dart';
import '../theme/app_theme.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(item.id);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context, cart, qty),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.imageUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppTheme.surface,
                          child: const Center(
                            child: Icon(Icons.fastfood,
                                color: AppTheme.textSecondary, size: 32),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    else
                      _placeholder(),
                    // Tags overlay
                    if (item.tags.isNotEmpty)
                      Positioned(
                        top: 8, left: 8,
                        child: Wrap(
                          spacing: 4,
                          children: item.tags.take(2).map((tag) =>
                            _TagChip(tag: tag)
                          ).toList(),
                        ),
                      ),
                    // Unavailable overlay
                    if (!item.available)
                      Container(
                        color: Colors.black.withOpacity(0.6),
                        child: const Center(
                          child: Text(
                            'UNAVAILABLE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.price.toStringAsFixed(2)} lei',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (item.available) _QuantityControl(item: item, qty: qty),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppTheme.surface,
    child: const Center(
      child: Icon(Icons.fastfood, color: AppTheme.textSecondary, size: 32),
    ),
  );

  void _showDetail(BuildContext context, CartProvider cart, int qty) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: cart,
        child: _ItemDetailSheet(item: item),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final MenuItem item;
  final int qty;

  const _QuantityControl({required this.item, required this.qty});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    if (qty == 0) {
      return GestureDetector(
        onTap: () => cart.add(item),
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.add, color: Colors.black, size: 18),
        ),
      );
    }

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: Icons.remove, onTap: () => cart.remove(item)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$qty',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          _Btn(icon: Icons.add, onTap: () => cart.add(item)),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Icon(icon, size: 14, color: AppTheme.accent),
    ),
  );
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final color = _color(tag);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color _color(String tag) {
    switch (tag.toLowerCase()) {
      case 'popular':    return const Color(0xFFE8A020);
      case 'spicy':      return const Color(0xFFE05C5C);
      case 'vegan':      return const Color(0xFF4CAF82);
      case 'new':        return const Color(0xFF7B6CF6);
      default:           return const Color(0xFF555555);
    }
  }
}

// ── Item detail bottom sheet ──────────────────────────────────────────────────

class _ItemDetailSheet extends StatelessWidget {
  final MenuItem item;
  const _ItemDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(item.id);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Image
          if (item.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                    Text(
                      '${item.price.toStringAsFixed(2)} lei',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14, height: 1.6,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Add / qty control
                qty == 0
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            cart.add(item);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add to order'),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _SheetBtn(
                                  icon: Icons.remove,
                                  onTap: () => cart.remove(item),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '$qty',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _SheetBtn(
                                  icon: Icons.add,
                                  onTap: () => cart.add(item),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Done',
                              style: TextStyle(color: AppTheme.accent),
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SheetBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
      ),
      child: Icon(icon, color: AppTheme.accent, size: 20),
    ),
  );
}
