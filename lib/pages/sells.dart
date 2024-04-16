import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../backend/functions.dart';


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
    _sellsDataFuture = fetchSellsData(context: context);
  }


  Future<void> scanBarcode() async {
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
                    // Quantity Field
                    TextFormField(
                      initialValue: '1', // Initial value for quantity
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                      ),
                      keyboardType: TextInputType.number, // Allow only numeric input
                      onChanged: (value) {
                        // Update the quantity when the input changes
                        quantity = int.tryParse(value) ?? 0;
                      },
                    ),
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

// Helper functions for timestamp conversion and formatting
  DateTime timestampToDate(Timestamp timestamp) {
    return timestamp.toDate();
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
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
                  _sellsDataFuture = fetchSellsData(selectedDate: selectedDate);// Refresh sells data with selected date
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
                              Text('Price: IQD ${sell['price'] ?? ''}'),
                              Text('Qty: ${sell['quantity'] ?? ''}'),
                              Text('seller: ${sell['seller'] ?? ''}'),
                              Text('expire: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(sell['expire']))}'),
                              Text('time: ${formatTimestamp(sell['time'])}'),
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
        onPressed: scanBarcode,
        child: Icon(Icons.qr_code_scanner),
      ),
    );
  }
}