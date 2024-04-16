import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tugas1_login/backend/user_provider.dart';

Future<List<Map<String, dynamic>>> fetchSellsData({String? selectedDate,required BuildContext context,}) async {
  selectedDate ??= DateTime.now().toString().substring(0, 10); // Use current date if no date is provided

  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final String userEmail = userProvider.userId;
  final String pharmacyId = userProvider.PharmacyId;
  try {
    // If selectedDate is '0', retrieve all sells
    if (selectedDate == '0') {
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
        print('All sells data fetched: $allSellsData');
        return allSellsData;
      } else {
        print('No sells data found');
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
        print('Sells data fetched for date $selectedDate: $sellsData');
        return sellsData;
      } else {
        print('No sells data found for date: $selectedDate');
        return [];
      }
    }
  } catch (error) {
    print("Error fetching sells data: $error");
    return [];
  }
}

Future<void> scanBarcode(BuildContext context, String userEmail, String pharmacyId) async {
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

  _showAddSellDialog(context, barcodeScanRes, userEmail, pharmacyId);
}


void _showAddSellDialog(BuildContext context, String scannedBarcode, String userEmail, String pharmacyId) async {
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
    print("Error fetching product data: $error");
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
    String? userEmail;
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
    print("Error adding sell: $error");
  }
}

DateTime timestampToDate(Timestamp timestamp) {
  return timestamp.toDate();
}

String formatTimestamp(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  return '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
}
