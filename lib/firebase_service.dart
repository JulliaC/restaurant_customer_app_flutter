import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class FirebaseService {
  final _db = FirebaseFirestore.instance;

  // ── Menu ──────────────────────────────────────────────────────────────────

  Stream<List<MenuItem>> menuStream() {
    return _db
        .collection('menu')
        .where('available', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MenuItem.fromFirestore(d.data(), d.id))
            .toList());
  }

  // ── Orders ────────────────────────────────────────────────────────────────

  /// Place a new order. Returns the new order document ID.
  Future<String> placeOrder(Order order) async {
    final ref = await _db.collection('orders').add(order.toFirestore());
    return ref.id;
  }

  /// Stream a single order's status updates (for the status tracker screen).
  Stream<OrderStatus> orderStatusStream(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      if (data == null) return OrderStatus.pending;
      return OrderStatus.fromString(data['status'] ?? 'pending');
    });
  }

  /// Stream all orders for a table (for the table view in the app).
  Stream<List<Order>> tableOrdersStream(int tableNumber) {
    return _db
        .collection('orders')
        .where('tableNumber', isEqualTo: tableNumber)
        .where('status', whereNotIn: ['served'])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final rawItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
              // We reconstruct lightweight CartItems for display only
              return Order(
                id: d.id,
                tableNumber: data['tableNumber'],
                items: rawItems
                    .map((i) => CartItem(
                          item: MenuItem(
                            id: i['itemId'] ?? '',
                            name: i['name'] ?? '',
                            description: '',
                            price: (i['price'] ?? 0).toDouble(),
                            category: '',
                            imageUrl: '',
                          ),
                          quantity: i['quantity'] ?? 1,
                          note: i['note'],
                        ))
                    .toList(),
                createdAt: DateTime.tryParse(data['createdAt'] ?? '') ??
                    DateTime.now(),
                status: OrderStatus.fromString(data['status'] ?? 'pending'),
              );
            }).toList());
  }
}
