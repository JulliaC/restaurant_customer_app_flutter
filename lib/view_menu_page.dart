import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'see_order_page.dart';
import 'details.dart';

class ViewMenuPage extends StatefulWidget {
  final int tableNumber;
  const ViewMenuPage({super.key, required this.tableNumber});

  @override
  _ViewMenuPageState createState() => _ViewMenuPageState();
}

class _ViewMenuPageState extends State<ViewMenuPage> {
  String selectedCategory = "all";

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<String> getImageUrl(String referencePath) async {
    try {
      return await FirebaseStorage.instance.ref(referencePath).getDownloadURL();
    } catch (e) {
      debugPrint('Error fetching image URL: $e');
      return '';
    }
  }

  Widget categoryButton(String category, String label) {
    final isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 17.0,
          fontWeight: FontWeight.bold,
          color: isSelected
              ? const Color(0xFFE4E2DD)
              : const Color.fromARGB(255, 156, 154, 152),
        ),
      ),
    );
  }

  Future<void> logMealSelection(String mealTitle) async {
    await _analytics.logEvent(
      name: 'meal_selected',
      parameters: {
        'meal_title': mealTitle,
        'table_number': widget.tableNumber,
      },
    );
    debugPrint('Meal selected: $mealTitle');
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF324051),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Menu').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No menu items available.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          var menuItems = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return selectedCategory == "all" || data['fel_mancare'] == selectedCategory;
          }).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                // Top of the page
                Container(
                  color: const Color(0xFFE4E2DD),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          left: screenWidth * 0.05,
                          top: screenHeight * 0.03,
                          bottom: screenHeight * 0.01,
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back_ios_new_outlined),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                          right: screenWidth * 0.05,
                          top: screenHeight * 0.03,
                          bottom: screenHeight * 0.01,
                        ),
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
                          child: const Text(
                            'Vezi comanda',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE4E2DD),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF324051),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Transition Image
                Container(
                  color: const Color(0xFFE4E2DD),
                  child: Image.asset(
                    'images/tranzitie_brazi.png',
                    width: screenWidth,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 15.0),

                const Padding(
                  padding: EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 0.0),
                  child: Center(
                    child: Text(
                      'Meniul zilei',
                      style: TextStyle(
                        fontSize: 23.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Color(0xFFE4E2DD),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.zero,
                  child: Divider(
                    height: 12.0,
                    indent: 35.0,
                    endIndent: 25.0,
                    color: Color(0xFFE4E2DD),
                  ),
                ),

                // Categories menu
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      categoryButton("all", "All"),
                      categoryButton("felul_intai", "Felul Întâi"),
                      categoryButton("felul_doi", "Felul Doi"),
                      categoryButton("desert", "Desert"),
                      categoryButton("bauturi", "Băuturi"),
                    ],
                  ),
                ),

                // Menu items
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    var item = menuItems[index].data() as Map<String, dynamic>;
                    String referencePath = item['imageRef'] ?? '';

                    return FutureBuilder<String>(
                      future: getImageUrl(referencePath),
                      builder: (context, snapshot) {
                        String imageUrl = snapshot.data ?? '';

                        return Container(
                          margin: EdgeInsets.fromLTRB(
                            screenWidth * 0.03,
                            screenWidth * 0.03,
                            screenWidth * 0.03,
                            0,
                          ),
                          child: Material(
                            elevation: 5.0,
                            color: const Color(0xFFE4E2DD),
                            borderRadius: BorderRadius.circular(20.0),
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15.0),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            height: screenHeight * 0.15,
                                            width: screenWidth * 0.3,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(child: CircularProgressIndicator());
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'],
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.04,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF324051),
                                          ),
                                        ),
                                        const SizedBox(height: 5.0),
                                        Text(
                                          item['description'] ?? '',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.035,
                                            color: const Color(0xFF324051),
                                          ),
                                        ),
                                        const SizedBox(height: 10.0),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${item['price']} RON',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF324051),
                                              ),
                                            ),
                                            const SizedBox(width: 20.0),
                                            ElevatedButton(
                                              onPressed: () async {
                                                await logMealSelection(item['title']);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => Details(
                                                      mealTitle: '${item['title']}',
                                                      tableNumber: widget.tableNumber,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Detalii',
                                                style: TextStyle(
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFE4E2DD),
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF324051),
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

                const SizedBox(height: 10.0),
              ],
            ),
          );
        },
      ),
    );
  }
}
