// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class DatabaseService {

//   // collection reference
//   final CollectionReference mealsCollection = FirebaseFirestore.instance.collection('meals');

//   Future updateMealsData(String mealTitle, String description, String ingredients, String infoNutritionale, String Alergeni, String category, bool meniulZilei) async
//   {
//     return await mealsCollection.doc();
//   }

// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DatabaseMethods{

  Future addOrder(Map<String,dynamic> orderInfoMap, String id) async {
    return await FirebaseFirestore.instance.collection("Menu").doc(id).set(orderInfoMap);
  }

//   Fluttertoast.showToast(
//         msg: "Order added successfully",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.CENTER,
//         timeInSecForIosWeb: 1,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//         fontSize: 16.0
// );






  // Future<void> addOrder(int tableNumber, List<Map<String, dynamic>> meals) async {
  //     // Reference to the orders collection
  //     CollectionReference orders = FirebaseFirestore.instance.collection('orders');
      
  //     // Create a new order document with auto-generated ID
  //     DocumentReference orderRef = await orders.add({
  //       'tableNumber': tableNumber,
  //       'orderTime': FieldValue.serverTimestamp(),
  //     });

  //     // Reference to the meals subcollection within the new order document
  //     CollectionReference mealsCollection = orderRef.collection('meals');

  //     // Add each meal as a document in the meals subcollection
  //     for (var meal in meals) {
  //       await mealsCollection.add(meal);
  //     }
  // }

}

