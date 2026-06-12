import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/menu_item.dart';
import '../services/firebase_service.dart';
import '../services/cart_provider.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/cart_fab.dart';
import '../theme/app_theme.dart';

class MenuScreen extends StatefulWidget {
  final int tableNumber;
  const MenuScreen({super.key, required this.tableNumber});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      body: StreamBuilder<List<MenuItem>>(
        stream: firebaseService.menuStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error loading menu',
                  style: Theme.of(context).textTheme.bodyMedium),
            );
          }

          final allItems = snap.data ?? [];
          final categories = [
            'All',
            ...{...allItems.map((i) => i.category)},
          ];

          final filtered = allItems.where((item) {
            final matchCat = _selectedCategory == 'All' ||
                item.category == _selectedCategory;
            final matchSearch = _searchQuery.isEmpty ||
                item.name.toLowerCase().contains(_searchQuery.toLowerCase());
            return matchCat && matchSearch;
          }).toList();

          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: AppTheme.background,
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Our Menu',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(fontSize: 26),
                            ),
                          ],
                        ),
                      ),
                      // Table badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.accent.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.table_restaurant,
                                color: AppTheme.accent, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              'Table ${widget.tableNumber}',
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search bar ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    style: Theme.of(context).textTheme.bodyLarge,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search the menu…',
                      hintStyle: Theme.of(context).textTheme.bodyMedium,
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppTheme.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ),

              // ── Category chips ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final selected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Section title ────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '${filtered.length} item${filtered.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),

              // ── Grid ─────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                sliver: filtered.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Column(
                            children: [
                              const Icon(Icons.search_off,
                                  color: AppTheme.textSecondary, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Nothing found',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, index) => MenuItemCard(item: filtered[index])
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: index * 60),
                                duration: 300.ms,
                              )
                              .slideY(begin: 0.1, end: 0),
                          childCount: filtered.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      // ── Floating cart bar ────────────────────────────────────────────────
      bottomNavigationBar: const CartFab(),
    );
  }
}
