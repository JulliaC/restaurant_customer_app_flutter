import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurant_app_flutter/see_order_page.dart';

class Details extends StatefulWidget {
  final String mealTitle;
  final int tableNumber;

  const Details({super.key, required this.mealTitle, required this.tableNumber});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  int portionCount = 1;

  Future<Map<String, dynamic>?> fetchMealDetails(String mealTitle) async {
    try {
      DocumentSnapshot mealDoc =
          await FirebaseFirestore.instance.collection('Menu').doc(mealTitle).get();

      if (mealDoc.exists) {
        return mealDoc.data() as Map<String, dynamic>;
      } else {
        print("Meal not found in the database.");
        return null;
      }
    } catch (e) {
      print("Error fetching meal details: $e");
      return null;
    }
  }

  Future<void> addToOrder(Map<String, dynamic> mealData) async {
    // IMPORTANT: order per table
    final orderRef = FirebaseFirestore.instance
        .collection('Orders')
        .doc('Order_${widget.tableNumber}');

    try {
      DocumentSnapshot orderSnapshot = await orderRef.get();

      Map<String, dynamic> orderData = orderSnapshot.exists
          ? orderSnapshot.data() as Map<String, dynamic>
          : {'items': [], 'total': 0, 'tableNumber': widget.tableNumber};

      List items = orderData['items'] ?? [];

      int itemIndex = items.indexWhere((item) => item['name'] == mealData['title']);
      if (itemIndex != -1) {
        items[itemIndex]['quantity'] += portionCount;
      } else {
        items.add({
          'name': mealData['title'],
          'quantity': portionCount,
          'price': num.tryParse(mealData['price'].toString()) ?? 0,
        });
      }

      orderData['total'] = items.fold<num>(
        0,
        (sum, item) =>
            sum + ((item['price'] as num) * (item['quantity'] as int)),
      );

      await orderRef.set({
        'tableNumber': widget.tableNumber,
        'items': items,
        'total': orderData['total'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adaugat la comanda!')),
      );
    } catch (e) {
      print("Upps! Nu am reusit sa adaugam la comanda: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Upps! Nu am reusit sa adaugam la comanda. Incearca din nou.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E2DD),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchMealDetails(widget.mealTitle),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'No details available for this meal.',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          final mealData = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row with back button and "Vezi comanda" button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Container(
                      margin: const EdgeInsets.only(right: 20.0, top: 25.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SeeOrderPage(
                                tableNumber: widget.tableNumber,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF324051),
                        ),
                        child: const Text(
                          'Vezi comanda',
                          style: TextStyle(
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

                SizedBox(height: 10.0),

                // White container with meal details
                Container(
                  margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  child: Material(
                    elevation: 5.0,
                    color: Color(0xFFFFFFFFFF),
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Food Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15.0),
                            child: Image.network(
                              mealData['imageRef'],
                              width: MediaQuery.of(context).size.width,
                              height: 200.0,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: CircularProgressIndicator(),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 15.0),

                          // Meal Title and Price
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  mealData['title'],
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF324051),
                                  ),
                                ),
                                Text(
                                  '${mealData['price']} RON',
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF324051),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Preparation Time
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              children: [
                                Text(
                                  'Timp de preparare',
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF324051),
                                  ),
                                ),
                                SizedBox(width: 10.0),
                                const Icon(Icons.alarm, color: Colors.grey),
                                const SizedBox(width: 5.0),
                                Text(
                                  '${mealData['preparationTime']} min',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF324051),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10.0),

                          // Sections
                          SectionTitle(title: 'Ingrediente'),
                          SectionContent(content: mealData['ingredients']),
                          SectionTitle(title: 'Informații nutriționale (100g)'),
                          SectionContent(content: mealData['valoareEnergetica']),
                          SectionTitle(title: 'Alergeni'),
                          SectionContent(content: mealData['alergeni']),

                          const SizedBox(height: 20.0),

                          // Add Portions and Add to Order Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (portionCount > 1) portionCount--;
                                  setState(() {});
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF324051),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: const Icon(Icons.remove, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              Text(
                                portionCount.toString(),
                                style: const TextStyle(
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF324051),
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              GestureDetector(
                                onTap: () {
                                  portionCount++;
                                  setState(() {});
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF324051),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 20.0),
                              ElevatedButton(
                                onPressed: () {
                                  addToOrder(mealData);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF324051),
                                ),
                                child: const Text(
                                  'Adaugă la comanda',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE4E2DD),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 45.0),

                          //=========================SEND ORDER=======================================//
                          const Center(
                            child: Text(
                              'Ati terminat comanda?',
                              style: TextStyle(
                                fontSize: 17.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF324051),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),

                          Container(
                            margin: const EdgeInsets.only(left: 10.0, right: 10.0),
                            child: const Center(
                              child: Text(
                                'Nu va faceti griji daca sunteti nehotarat, mai putem adauga la comanda mai tarziu',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 138, 136, 132),
                                  fontFamily: 'Poppins',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                          const SizedBox(height: 15.0),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SeeOrderPage(
                                        tableNumber: widget.tableNumber,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF324051),
                                ),
                                child: const Text(
                                  'Vezi comanda',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE4E2DD),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15.0),
                              ElevatedButton(
                                onPressed: () {
                                  // Keep your design; sending is inside SeeOrderPage
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SeeOrderPage(
                                        tableNumber: widget.tableNumber,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF324051),
                                ),
                                child: const Text(
                                  'Trimite comanda',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE4E2DD),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 50.0),
                        ],
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

// Section Title Widget
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 61, 76, 95),
        ),
      ),
    );
  }
}

// Section Content Widget
class SectionContent extends StatelessWidget {
  final String content;
  const SectionContent({required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 12.0,
          color: Color.fromARGB(255, 61, 76, 95),
        ),
      ),
    );
  }
}
