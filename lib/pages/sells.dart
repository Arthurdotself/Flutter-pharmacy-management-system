import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Sells extends StatefulWidget {
  final String userEmail;
  final String pharmacyId;
  const Sells({Key? key, required this.userEmail, required this.pharmacyId}) : super(key: key);

  @override
  _SellsState createState() => _SellsState();
}

class _SellsState extends State<Sells> {
  String _selectedTimePeriod = 'Today';
  late Future<List<Map<String, dynamic>>> _sellsDataFuture;
  List<dynamic> shipments = []; // Declare shipments list at class level

  @override
  void initState() {
    super.initState();
    _sellsDataFuture = fetchSellsData();
  }

  Future<List<Map<String, dynamic>>> fetchSellsData({String? selectedDate}) async {
    selectedDate ??= DateTime.now().toString().substring(0, 10); // Use current date if no date is provided

    try {
      // Fetch pharmacyId from user document
      final userDataSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userEmail)
          .get();
      final pharmacyId = userDataSnapshot['pharmacyId'];
      print('Pharmacy ID: $pharmacyId');

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




  Future<void> _scanBarcode() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
      '#ff6666', // Scanner overlay color
      'Cancel', // Cancel button text
      true, // Use flash
      ScanMode.BARCODE, // Scan mode
    );

    if (!mounted) return;

    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned Barcode: $barcodeScanRes'),
          duration: const Duration(seconds: 3), // Adjust the duration as needed
        ),
      );

      _showAddSellDialog(barcodeScanRes);
    });
  }

  void _showAddSellDialog(String scannedBarcode) async {
    String productName = '';
    double price = 0.0;
    int quantity = 0;
    String selectedExpirationDate = '';
    List<String> expirationDates = [
    ]; // List to hold available expiration dates

    try {
      final docRef = FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(widget.pharmacyId)
          .collection('medicines')
          .doc(scannedBarcode);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        productName = data['Name'] ?? '';
        quantity = data['quantity'] ?? 0;

        // Assign value to shipments
        shipments = data['shipments'] ?? []; // Assign the value here

        if (shipments.isNotEmpty) {
          // Populate expirationDates list with available expiration dates
          expirationDates = shipments.map((shipment) {
            Timestamp expireTimestamp = shipment['expire'];
            return expireTimestamp.toDate().toString();
          }).toList();

          // Sort expiration dates in ascending order
          expirationDates.sort((a, b) =>
              DateTime.parse(a).compareTo(DateTime.parse(b)));

          // Find the closest expiration date that is not expired
          final currentDate = DateTime.now();
          for (final date in expirationDates) {
            final expirationDate = DateTime.parse(date);
            if (expirationDate.isAfter(currentDate)) {
              selectedExpirationDate = date;
              // Find the shipment data corresponding to the selected expiration date
              for (final shipment in shipments) {
                Timestamp expireTimestamp = shipment['expire'];
                String expireDate = expireTimestamp.toDate().toString();
                if (expireDate == selectedExpirationDate) {
                  // Populate the price from the shipment data
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
                    // Product Name Field
                    Text(selectedExpirationDate.isNotEmpty
                        ? 'Product Name: $productName'
                        : 'No product name available'),

                    // Price Field
                    Text(selectedExpirationDate.isNotEmpty
                        ? 'Price: $price'
                        : 'No price available'),

                    // Expiration Date Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedExpirationDate,
                      decoration: const InputDecoration(
                          labelText: 'Expiration Date'),
                      onChanged: (value) {
                        setState(() {
                          selectedExpirationDate = value!;
                          // Update the price when the expiration date changes
                          for (final shipment in shipments) {
                            Timestamp expireTimestamp = shipment['expire'];
                            String expireDate = expireTimestamp.toDate()
                                .toString();
                            if (expireDate == selectedExpirationDate) {
                              // Populate the price from the shipment data
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
                    // Perform add sell operation here
                    _addSell(scannedBarcode, productName, price, quantity,
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


  void _addSell(String scannedBarcode, String productName, double price,
      int quantity, String expire) async {
    String currentDate = DateTime.now().toString().substring(0, 10);
    String selectedDate = _selectedTimePeriod == 'Today'
        ? currentDate
        : ''; // You might need to handle other time periods accordingly
    try {
      final pharmacySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userEmail)
          .get();
      final pharmacyId = pharmacySnapshot['pharmacyId'];

      final sellRef = FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('sells')
          .doc(selectedDate)
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
        'seller': widget.userEmail
      });
    } catch (error) {
      print("Error adding sell: $error");
    }
  }

  String _getDateForPeriod(String period) {
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sells'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedTimePeriod,
              decoration: const InputDecoration(
                labelText: 'Time Period',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  String selectedDate = _getDateForPeriod(value!);
                  _selectedTimePeriod = value;
                  _sellsDataFuture = fetchSellsData(selectedDate: selectedDate); // Refresh sells data with selected date
                  }
                );
              },
              items: [
                'Today',
                'Yesterday',
                'All', // Add 'All' option
              ].map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _sellsDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else {
                  List<Map<String, dynamic>> sellsData = snapshot.data ?? [];
                  print(sellsData); // Print sellsData here
                  if (sellsData.isEmpty) {
                    return Center(child: Text(
                        "No sells data found for $_selectedTimePeriod"));
                  } else {
                    return ListView.builder(
                      itemCount: sellsData.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> sell = sellsData[index];
                        return ListTile(
                          title: Text(sell['productName'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Price: \$${sell['price'] ?? ''}'),
                              Text('Qty: ${sell['quantity'] ?? ''}'),
                              Text('seller: ${sell['seller'] ?? ''}'),
                              Text('expire: ${sell['expire'] ?? ''}'),
                              Text('time: ${sell['time'] ?? ''}'),// Display the document ID here
                            ],
                          ),
                          onTap: () {
                            // Add functionality for tapping on a sold product if needed
                          },
                        );
                      },
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcode,
        child: Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
