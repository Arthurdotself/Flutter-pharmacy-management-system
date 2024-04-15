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

  @override
  void initState() {
    super.initState();
    _sellsDataFuture = fetchSellsData();
  }

  Future<List<Map<String, dynamic>>> fetchSellsData() async {
    String currentDate = DateTime.now().toString().substring(0, 10);
    String selectedDate = _selectedTimePeriod == 'Today' ? currentDate : ''; // You might need to handle other time periods accordingly
    try {
      // Fetch pharmacyId from user document
      final userDataSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userEmail)
          .get();
      final pharmacyId = userDataSnapshot['pharmacyId'];
      print('Pharmacy ID: $pharmacyId');

      DocumentSnapshot sellsDocSnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('sells')
          .doc(selectedDate) // Get the document directly by document ID (selectedDate)
          .get();

      if (sellsDocSnapshot.exists) {
        Map<String, dynamic> sellsData = sellsDocSnapshot.data() as Map<String, dynamic>;
        print('Sells data fetched: $sellsData');
        return [sellsData]; // Return a list with the fetched sells data
      } else {
        print('No sells data found for date: $selectedDate');
        return []; // Return an empty list if no sells data is found
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
        price = data['price'] != null ? double.parse(data['price'].toString()) : 0.0;
        quantity = data['quantity'] != null ? int.parse(data['quantity'].toString()) : 0;

        // Now we need to retrieve the expiration dates from the shipments array
        List<dynamic> shipments = data['shipments'] ?? [];
        if (shipments.isNotEmpty) {
          // For simplicity, let's just use the first expiration date from the shipments array
          selectedExpirationDate = shipments[0]['expire'] ?? '';
        }
      }
    } catch (error) {
      print("Error fetching product data: $error");
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Sell"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    productName = value;
                  },
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                TextField(
                  onChanged: (value) {
                    price = double.parse(value);
                  },
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  onChanged: (value) {
                    quantity = int.parse(value);
                  },
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                // Optionally, you can display the selected expiration date or provide a dropdown to choose from the available expiration dates
                Text(selectedExpirationDate.isNotEmpty ? 'Selected Expiration Date: $selectedExpirationDate' : 'No expiration date selected'),
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
                _addSell(scannedBarcode, productName, price, quantity, selectedExpirationDate);
                Navigator.of(context).pop();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }



  void _addSell(String scannedBarcode, String productName, double price, int quantity, String expire) async {
    String currentDate = DateTime.now().toString().substring(0, 10);
    String selectedDate = _selectedTimePeriod == 'Today' ? currentDate : ''; // You might need to handle other time periods accordingly
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
          .collection('dailySells') // Create a subcollection to store daily sells
          .doc(); // Automatically generate a unique document ID

      // Create a new sell document inside the selectedDate document
      await sellRef.set({
        'productName': productName,
        'price': price,
        'quantity': quantity,
        'expire': expire,
      });
    } catch (error) {
      print("Error adding sell: $error");
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
                  _selectedTimePeriod = value!;
                  _sellsDataFuture = fetchSellsData(); // Refresh sells data
                });
              },
              items: ['Today', 'Yesterday', 'Last Week', 'Last Month', 'Pick Date']
                  .map((period) => DropdownMenuItem(
                value: period,
                child: Text(period),
              ))
                  .toList(),
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
                  return ListView.builder(
                    itemCount: sellsData.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> sell = sellsData[index];
                      return ListTile(
                        title: Text(sell['productName'] ?? ''),
                        subtitle: Text('Price: \$${sell['price'] ?? ''}'),
                        trailing: Text('Qty: ${sell['quantity'] ?? ''}'),
                        onTap: () {
                          // Add functionality for tapping on a sold product if needed
                        },
                      );
                    },
                  );
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
