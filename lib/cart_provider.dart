import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  int _tableNumber = 0;
  String? _pendingOrderId;

  List<CartItem> get items => List.unmodifiable(_items);
  int get tableNumber => _tableNumber;
  String? get pendingOrderId => _pendingOrderId;

  int get totalCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get totalPrice => _items.fold(0, (sum, i) => sum + i.subtotal);
  bool get isEmpty => _items.isEmpty;

  void setTable(int table) {
    _tableNumber = table;
    notifyListeners();
  }

  void setPendingOrder(String orderId) {
    _pendingOrderId = orderId;
    notifyListeners();
  }

  void clearOrder() {
    _items.clear();
    _pendingOrderId = null;
    notifyListeners();
  }

  CartItem? getItem(String itemId) {
    try {
      return _items.firstWhere((i) => i.item.id == itemId);
    } catch (_) {
      return null;
    }
  }

  int quantityOf(String itemId) => getItem(itemId)?.quantity ?? 0;

  void add(MenuItem item) {
    final existing = getItem(item.id);
    if (existing != null) {
      existing.quantity++;
    } else {
      _items.add(CartItem(item: item));
    }
    notifyListeners();
  }

  void remove(MenuItem item) {
    final existing = getItem(item.id);
    if (existing == null) return;
    if (existing.quantity > 1) {
      existing.quantity--;
    } else {
      _items.remove(existing);
    }
    notifyListeners();
  }

  void removeAll(String itemId) {
    _items.removeWhere((i) => i.item.id == itemId);
    notifyListeners();
  }

  void setNote(String itemId, String note) {
    final item = getItem(itemId);
    if (item != null) {
      item.note = note;
      notifyListeners();
    }
  }
}
