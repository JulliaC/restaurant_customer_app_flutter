import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class SeeOrderPage extends StatefulWidget {
  final int tableNumber;
  const SeeOrderPage({super.key, required this.tableNumber});

  @override
  State<SeeOrderPage> createState() => _SeeOrderPageState();
}

FirebaseAnalytics analytics = FirebaseAnalytics.instance;

void logPageView(String pageName) {
  analytics.logEvent(
    name: 'page_view',
    parameters: {'page_name': pageName},
  );
}

class _SeeOrderPageState extends State<SeeOrderPage> {
  String get _orderDocId => 'Order_${widget.tableNumber}';

  @override
  void initState() {
    super.initState();
    logPageView('SeeOrderPage');
  }

  // Fetch the order from Firestore (PER TABLE)
  Future<Map<String, dynamic>?> fetchOrder() async {
    try {
      DocumentSnapshot orderDoc = await FirebaseFirestore.instance
          .collection('Orders')
          .doc(_orderDocId)
          .get();

      if (orderDoc.exists) {
        Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
        orderData['items'] = orderData['items'] ?? [];
        orderData['total'] = orderData['total'] ?? 0;
        return orderData;
      } else {
        return {'items': [], 'total': 0};
      }
    } catch (e) {
      print("Error fetching order: $e");
      return null;
    }
  }

  // Fetch image URL from Firebase Storage based on meal name
  Future<String> getImageUrl(String mealName) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Menu')
          .where('title', isEqualTo: mealName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String referencePath = querySnapshot.docs.first['imageRef'];
        return await FirebaseStorage.instance.ref(referencePath).getDownloadURL();
      } else {
        debugPrint('Meal not found in Menu collection.');
        return '';
      }
    } catch (e) {
      debugPrint('Error fetching image URL: $e');
      return '';
    }
  }

  // Update the quantity of an item in the order
  Future<void> updateItemQuantity(String itemName, int newQuantity) async {
    final orderRef =
        FirebaseFirestore.instance.collection('Orders').doc(_orderDocId);

    DocumentSnapshot orderSnapshot = await orderRef.get();
    if (!orderSnapshot.exists) return;

    Map<String, dynamic> orderData =
        orderSnapshot.data() as Map<String, dynamic>;
    List items = orderData['items'] ?? [];

    int itemIndex = items.indexWhere((item) => item['name'] == itemName);
    if (itemIndex != -1) {
      if (newQuantity > 0) {
        items[itemIndex]['quantity'] = newQuantity;
      } else {
        items.removeAt(itemIndex);
      }

      orderData['total'] = items.fold<num>(
        0,
        (sum, item) => sum + (item['price'] * item['quantity']),
      );

      await orderRef.set({
        'tableNumber': widget.tableNumber,
        'items': items,
        'total': orderData['total'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {}); // Refresh UI
    }
  }

  // SEND ORDER TO KITCHEN
  Future<void> sendOrderToKitchen() async {
    final orderData = await fetchOrder();
    if (orderData == null) return;

    final List items = (orderData['items'] ?? []) as List;
    final num total = (orderData['total'] ?? 0) as num;

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comanda este goală.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('KitchenOrders').add({
        'tableNumber': widget.tableNumber,
        'items': items,
        'total': total,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear order after sending
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(_orderDocId)
          .set({
        'tableNumber': widget.tableNumber,
        'items': [],
        'total': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comanda pentru masa ${widget.tableNumber} a fost trimisă!')),
      );

      setState(() {});
    } catch (e) {
      debugPrint('Error sending order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eroare la trimiterea comenzii.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFE4E2DD),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchOrder(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!['items'].isEmpty) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 20.0, top: 20.0),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    'No items in the order. (Masa ${widget.tableNumber})',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF324051),
                    ),
                  ),
                ),
              ],
            );
          }

          final orderData = snapshot.data!;
          final items = orderData['items'];
          final total = orderData['total'];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 20.0, top: 20.0),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_outlined),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.0),

                // Order items
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    String mealName = item['name'];

                    return FutureBuilder<String>(
                      future: getImageUrl(mealName),
                      builder: (context, snapshot) {
                        String imageUrl = snapshot.data ?? '';

                        return Container(
                          margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                          child: Material(
                            elevation: 5.0,
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(20.0),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15.0),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            height: screenHeight * 0.15,
                                            width: screenWidth * 0.3,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const Center(
                                                child: CircularProgressIndicator(),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: CircularProgressIndicator(),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey[300],
                                            child: CircularProgressIndicator(),
                                          ),
                                  ),

                                  const SizedBox(width: 10.0),

                                  // Item details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontSize: 17.0,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF324051),
                                          ),
                                        ),

                                        SizedBox(height: 45.0),

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                '${item['price'] * item['quantity']} RON',
                                                style: const TextStyle(
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF324051),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 20.0),

                                            // Remove button
                                            GestureDetector(
                                              onTap: () {
                                                updateItemQuantity(
                                                    item['name'], item['quantity'] - 1);
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF324051),
                                                  borderRadius: BorderRadius.circular(8.0),
                                                ),
                                                padding: const EdgeInsets.all(4.0),
                                                child: const Icon(
                                                  Icons.remove,
                                                  color: Colors.white,
                                                  size: 20.0,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10.0),

                                            // Quantity
                                            Text(
                                              '${item['quantity']}',
                                              style: const TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF324051),
                                              ),
                                            ),
                                            const SizedBox(width: 10.0),

                                            // Add button
                                            GestureDetector(
                                              onTap: () {
                                                updateItemQuantity(
                                                    item['name'], item['quantity'] + 1);
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF324051),
                                                  borderRadius: BorderRadius.circular(8.0),
                                                ),
                                                padding: const EdgeInsets.all(4.0),
                                                child: const Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                  size: 20.0,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 15.0),

                                            // Delete button
                                            GestureDetector(
                                              onTap: () {
                                                updateItemQuantity(item['name'], 0);
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(8.0),
                                                ),
                                                padding: const EdgeInsets.all(4.0),
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: Colors.white,
                                                  size: 20.0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Total price
                Container(
                  margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  child: Material(
                    elevation: 5.0,
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(20.0),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF324051),
                            ),
                          ),
                          Text(
                            '$total RON',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF324051),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // SEND ORDER BUTTON (same style)
                Container(
                  margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 20.0),
                  child: ElevatedButton(
                    onPressed: sendOrderToKitchen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF324051),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                    child: Text(
                      'Trimite comanda (Masa ${widget.tableNumber})',
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE4E2DD),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
