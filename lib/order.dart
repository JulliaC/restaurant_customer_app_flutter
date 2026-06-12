import 'menu_item.dart';

class CartItem {
  final MenuItem item;
  int quantity;
  String? note;

  CartItem({required this.item, this.quantity = 1, this.note});

  double get subtotal => item.price * quantity;

  Map<String, dynamic> toMap() => {
    'itemId': item.id,
    'name': item.name,
    'price': item.price,
    'quantity': quantity,
    'subtotal': subtotal,
    if (note != null && note!.isNotEmpty) 'note': note,
  };
}

class Order {
  final String id;
  final int tableNumber;
  final List<CartItem> items;
  final DateTime createdAt;
  OrderStatus status;
  final String? customerNote;

  Order({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.createdAt,
    this.status = OrderStatus.pending,
    this.customerNote,
  });

  double get total => items.fold(0, (sum, i) => sum + i.subtotal);

  Map<String, dynamic> toFirestore() => {
    'tableNumber': tableNumber,
    'items': items.map((i) => i.toMap()).toList(),
    'total': total,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'timestamp': createdAt.millisecondsSinceEpoch,
    if (customerNote != null && customerNote!.isNotEmpty)
      'customerNote': customerNote,
  };
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  served;

  String get label {
    switch (this) {
      case OrderStatus.pending:    return 'Waiting for confirmation';
      case OrderStatus.confirmed:  return 'Order confirmed';
      case OrderStatus.preparing:  return 'Being prepared';
      case OrderStatus.ready:      return 'Ready to serve!';
      case OrderStatus.served:     return 'Served — enjoy!';
    }
  }

  static OrderStatus fromString(String s) =>
      OrderStatus.values.firstWhere((e) => e.name == s,
          orElse: () => OrderStatus.pending);
}
