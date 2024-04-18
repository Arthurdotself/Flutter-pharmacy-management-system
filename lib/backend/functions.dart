import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tugas1_login/backend/user_provider.dart';
import 'dart:io';


late String userEmail;
late String pharmacyId;


//-------------------------fecth sells-------------------------------
void setUserEmail(BuildContext context) {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  userEmail = userProvider.userId;
  pharmacyId = userProvider.PharmacyId;
}

Future<List<Map<String, dynamic>>> fetchSellsData( {String? selectedDate}) async {
  selectedDate ??= DateTime.now().toString().substring(0, 10);; // Use current date if no date is provided

  try {
    if (selectedDate == '0') {
      // Retrieve all sells
      QuerySnapshot sellsQuerySnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('sells')
          .get();

      List<Map<String, dynamic>> allSellsData = [];
      for (QueryDocumentSnapshot doc in sellsQuerySnapshot.docs) {
        QuerySnapshot dailySellsQuerySnapshot = await doc.reference.collection('dailySells').get();
        dailySellsQuerySnapshot.docs.forEach((dailyDoc) {
          allSellsData.add(dailyDoc.data() as Map<String, dynamic>);
        });
      }
      if (allSellsData.isNotEmpty) {
        return allSellsData;
      } else {
        return [];
      }
    } else if (selectedDate == '7') {
      // Retrieve sells data for the last 7 days
      List<Map<String, dynamic>> sellsData = [];
      for (int i = 0; i < 7; i++) {
        // Calculate the date i days ago
        DateTime date = DateTime.now().subtract(Duration(days: i));
        String dateString = date.toString().substring(0, 10);

        QuerySnapshot dailySellsQuerySnapshot = await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(pharmacyId)
            .collection('sells')
            .doc(dateString)
            .collection('dailySells')
            .get();

        dailySellsQuerySnapshot.docs.forEach((doc) {
          sellsData.add(doc.data() as Map<String, dynamic>);
        });
       // print(sellsData);
      }

      if (sellsData.isNotEmpty) {
        return sellsData;
      } else {
        return [];
      }
    } else {
      // Retrieve sells data for the specified date
      QuerySnapshot dailySellsQuerySnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('sells')
          .doc(selectedDate)
          .collection('dailySells')
          .get();

      List<Map<String, dynamic>> sellsData = [];
      dailySellsQuerySnapshot.docs.forEach((doc) {
        sellsData.add(doc.data() as Map<String, dynamic>);
      });

      if (sellsData.isNotEmpty) {
        return sellsData;
      } else {
        return [];
      }
    }
  } catch (error) {
    print(error);
    return [];
  }
}


Future<void> sellscanBarcode(BuildContext context) async {
  String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
    '#ff6666', // Scanner overlay color
    'Cancel', // Cancel button text
    true, // Use flash
    ScanMode.BARCODE, // Scan mode
  );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Scanned Barcode: $barcodeScanRes'),
      duration: const Duration(seconds: 3), // Adjust the duration as needed
    ),
  );

  _showAddSellDialog(context, barcodeScanRes);
}


void _showAddSellDialog(BuildContext context, String scannedBarcode) async {
  String productName = '';
  double price = 0.0;
  int quantity = 0;
  String selectedExpirationDate = '';
  List<String> expirationDates = [];
  List<dynamic> shipments = [];
  try {
    final docRef = FirebaseFirestore.instance
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('medicines')
        .doc(scannedBarcode);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      productName = data['Name'] ?? '';
      quantity = data['quantity'] ?? 0;

      // Assign value to shipments
      shipments = data['shipments'] ?? [];

      if (shipments.isNotEmpty) {
        expirationDates = shipments.map((shipment) {
          Timestamp expireTimestamp = shipment['expire'];
          return expireTimestamp.toDate().toString();
        }).toList();

        expirationDates.sort((a, b) =>
            DateTime.parse(a).compareTo(DateTime.parse(b)));

        final currentDate = DateTime.now();
        for (final date in expirationDates) {
          final expirationDate = DateTime.parse(date);
          if (expirationDate.isAfter(currentDate)) {
            selectedExpirationDate = date;
            for (final shipment in shipments) {
              Timestamp expireTimestamp = shipment['expire'];
              String expireDate = expireTimestamp.toDate().toString();
              if (expireDate == selectedExpirationDate) {
                price = shipment['price'] != null ? double.parse(
                    shipment['price'].toString()) : 0.0;
                break;
              }
            }
            break;
          }
        }
      }
    }
  } catch (error) {
    print(error);
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Add Sell"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  Text(selectedExpirationDate.isNotEmpty
                      ? 'Product Name: $productName'
                      : 'No product name available'),

                  Text(selectedExpirationDate.isNotEmpty
                      ? 'Price: $price'
                      : 'No price available'),
                  TextFormField(
                    initialValue: '1',
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      quantity = int.tryParse(value) ?? 0;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedExpirationDate,
                    decoration: const InputDecoration(
                        labelText: 'Expiration Date'),
                    onChanged: (value) {
                      setState(() {
                        selectedExpirationDate = value!;
                        for (final shipment in shipments) {
                          Timestamp expireTimestamp = shipment['expire'];
                          String expireDate = expireTimestamp.toDate()
                              .toString();
                          if (expireDate == selectedExpirationDate) {
                            price = shipment['price'] != null ? double.parse(
                                shipment['price'].toString()) : 0.0;
                            break;
                          }
                        }
                      });
                    },
                    items: expirationDates.map((date) {
                      return DropdownMenuItem(
                        value: date,
                        child: Text(date),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  addSell(scannedBarcode, productName, price, quantity,
                      selectedExpirationDate);
                  Navigator.of(context).pop();
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
}

void addSell(String scannedBarcode, String productName, double price,
    int quantity, String expire) async {
  String currentDate = DateTime.now().toString().substring(0, 10);
  try {

    final pharmacySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .get();
    final pharmacyId = pharmacySnapshot['pharmacyId'];

    final sellRef = FirebaseFirestore.instance
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('sells')
        .doc(currentDate)
        .collection(
        'dailySells') // Create a subcollection to store daily sells
        .doc(); // Automatically generate a unique document ID

    // Add current time
    DateTime currentTime = DateTime.now();

    // Create a new sell document inside the selectedDate document
    await sellRef.set({
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'expire': expire,
      'time': currentTime, // Add current time
      'seller': userEmail
    });
  } catch (error) {
    print(error);
  }
}

DateTime timestampToDate(Timestamp timestamp) {
  return timestamp.toDate();
}

String formatTimestamp(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  return '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
}

String getDateForPeriod(String period) {
  DateTime today = DateTime.now();
  switch (period) {
    case 'Today':
      return today.toString().substring(0, 10);
    case 'Yesterday':
      DateTime yesterday = today.subtract(Duration(days: 1));
      return yesterday.toString().substring(0, 10);
    case 'All':
      return '0';
    default:
      return '';
  }
}


//-------------------------fecth sells-------------------------------

Future<int> getSellsCount() async {
  final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('pharmacies').doc(pharmacyId).collection('sells').get();
  return snapshot.docs.length;
}

Future<int> countTasks(BuildContext context) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').doc(userEmail).collection('tasks').get();

    int totalTasks = querySnapshot.size;
    int completedTasks = querySnapshot.docs.where((doc) => doc['isCompleted'] == true).length;
    int pendingTasks = totalTasks - completedTasks;

    print('Total tasks: $totalTasks');
    print('Completed tasks: $completedTasks');
    print('Pending tasks: $pendingTasks');

    return pendingTasks; // Return the total number of tasks
  } catch (error) {
    print('Error counting tasks: $error');
    return 0; // Return 0 in case of an error
  }
}

Future<int> getMedicinesCount() async {
  final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('pharmacies').doc(pharmacyId).collection('medicines').get();

  return snapshot.docs.length;
}

Future<int> getExpiringCount() async {
  // Get today's date
  DateTime now = DateTime.now();

  // Define the start and end dates for the range (e.g., 24 hours before and after today)
  DateTime startDate = DateTime(now.year, now.month, now.day - 1); // 24 hours before today
  DateTime endDate = DateTime(now.year, now.month, now.day + 1); // 24 hours after today

  // Query shipments within the date range
  QuerySnapshot shipmentsSnapshot = await FirebaseFirestore.instance
      .collection('pharmacies')
      .doc(pharmacyId)
      .collection('medicines')
      .where('shipments.date', isGreaterThanOrEqualTo: startDate, isLessThan: endDate)
      .get();

  // Initialize the count of medicines
  int medicinesCount = 0;

  // Iterate over each document in the shipments collection
  for (QueryDocumentSnapshot doc in shipmentsSnapshot.docs) {
    // Get the list of shipments for the current document
    List<dynamic> shipments = doc['shipments'];

    // Iterate over each shipment in the list
    for (dynamic shipment in shipments) {
      // Extract the shipment date
      DateTime shipmentDate = DateTime.parse(shipment['date']);

      // Check if the shipment date is within the specified range
      if (shipmentDate.isAfter(startDate) && shipmentDate.isBefore(endDate)) {
        // Increment the count of medicines associated with this shipment
        medicinesCount++;
      }
    }
  }

  return medicinesCount;
}

Future<void> getImage(ImagePicker picker, ImageSource source) async {
  final pickedFile = await picker.pickImage(source: source);

  if (pickedFile != null) {
    File imageFile = File(pickedFile.path);

    try {
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('${userEmail}_avatar.jpg');

      await ref.putFile(imageFile);
      String downloadURL = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(userEmail).update({'photoURL': downloadURL});
    } catch (error) {
      print('Error uploading image: $error');
    }
  }
}

Future<void> uploadImage(BuildContext context) async {
  final ImagePicker picker = ImagePicker(); // Declare _picker here

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Choose Image Source'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              GestureDetector(
                child: Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  getImage(picker, ImageSource.camera);
                },
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
              ),
              GestureDetector(
                child: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  getImage(picker, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
class CounterData {
  final String date;
  final int count;

  CounterData(this.date, this.count);
}
//-------------------------dashboard ------------------------------------------------------------


Stream<QuerySnapshot> getTasksStream(BuildContext context) {
  return FirebaseFirestore.instance.collection('users').doc(userEmail).collection('tasks').where('isCompleted', isEqualTo: false).snapshots();
}

Stream<QuerySnapshot> getCompletedTasksStream(BuildContext context) {
  return FirebaseFirestore.instance.collection('users').doc(userEmail).collection('tasks').where('isCompleted', isEqualTo: true).snapshots();
}
class Task {
  final String documentId; // Add this property to store the document ID
  final String description;
  final String title;

  final bool isCompleted;

  Task({
    required this.documentId,
    required this.description,
    required this.title,
    required this.isCompleted,
  });
}
void toggleTaskCompletion(BuildContext context, Task task) async {
  try {
    CollectionReference tasksCollection = FirebaseFirestore.instance.collection('users').doc(userEmail).collection('tasks');

    await tasksCollection.doc(task.documentId).update({
      'isCompleted': !task.isCompleted,
    });

    if (kDebugMode) {
      print('Task completion status updated successfully');
    }
  } catch (error) {
    if (kDebugMode) {
      print('Error updating task completion status: $error');
    }
  }
}
//------------------------- ExpiringExpired ------------------------------------------------------------

