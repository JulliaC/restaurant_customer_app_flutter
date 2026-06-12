class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool available;
  final List<String> tags; // e.g. ['spicy', 'vegan', 'popular']

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.available = true,
    this.tags = const [],
  });

  factory MenuItem.fromFirestore(Map<String, dynamic> data, String id) {
    return MenuItem(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? 'Other',
      imageUrl: data['imageUrl'] ?? '',
      available: data['available'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'category': category,
  };
}
