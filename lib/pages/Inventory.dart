import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class Inventory extends StatefulWidget {
  final String userEmail;

  const Inventory({Key? key, required this.userEmail}) : super(key: key);

  @override
  _InventoryState createState() => _InventoryState();
}
late Timer _timer;

class _InventoryState extends State<Inventory> {
  void _fetchAndUpdateMedicines() {
    _fetchMedicines(); // Fetch medicines from Firebase and update _data
    setState(() {}); // Update the UI
  }

  @override
  void initState() {
    super.initState();
    _fetchMedicines();
    // Start the timer when the widget is initialized
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      _fetchAndUpdateMedicines(); // Call the function to fetch and update medicines
    });
  }

  @override
  void dispose() {
    super.dispose();
    // Cancel the timer when the widget is disposed to prevent memory leaks
    _timer.cancel();
  }

  bool _sortAscending = true;
  int _sortColumnIndex = 0;

  final List<Map<String, dynamic>> _data = [];

  // @override
  // void initState() {
  //   super.initState();
  //   _fetchMedicines();
  // }


  Future<void> _fetchMedicines() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userEmail)
        .collection('medicines')
        .get();

    final List<Map<String, dynamic>> newData = [];

    querySnapshot.docs.forEach((doc) {
      final id = doc.id;
      final data = doc.data() as Map<String, dynamic>;
      final name = data['Name'] ?? '';
      final dose = data['Dose'] ?? '';
      final brand = data['Brand'] ?? '';
      final shipments = data['shipments'] ?? []; // Fetch the 'shipments' array

      newData.add({
        'id': id,
        'Name': name,
        'Dose': dose,
        'Brand': brand,
        'Shipments': shipments, // Include the 'shipments' array in the map
      });
    });

    setState(() {
      _data.clear();
      _data.addAll(newData);
    });
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
          duration: Duration(seconds: 3), // Adjust the duration as needed
        ),
      );

      _showAddMedicineDialog(barcodeScanRes);
    });
  }

  void _showAddMedicineDialog(String scannedBarcode) async {
    String brand = '';
    int dose = 0;
    int cost = 0;
    String expire = '';
    String name = '';
    int price = 0;
    int amount = 0;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userEmail)
        .collection('medicines')
        .doc(scannedBarcode);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      // Document exists, populate fields with existing values
      final data = docSnapshot.data() as Map<String, dynamic>;
      name = data['Name'] ?? '';
      brand = data['Brand'] ?? '';
      dose = data['Dose'] ?? 0;
      // Populate other fields as needed
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Medicine"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    name = value;
                  },
                  decoration: InputDecoration(labelText: 'Name'),
                  controller: TextEditingController(text: name),
                ),
                TextField(
                  onChanged: (value) {
                    brand = value;
                  },
                  decoration: InputDecoration(labelText: 'Brand'),
                  controller: TextEditingController(text: brand),
                ),
                TextField(
                  onChanged: (value) {
                    dose = int.tryParse(value) ?? 0;
                  },
                  decoration: InputDecoration(labelText: 'Dose'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: dose.toString()),
                ),
                TextField(
                  onChanged: (value) {
                    cost = int.tryParse(value) ?? 0;
                  },
                  decoration: InputDecoration(labelText: 'Cost'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  onChanged: (value) {
                    expire = value;
                  },
                  decoration: InputDecoration(labelText: 'Expire'),
                ),
                TextField(
                  onChanged: (value) {
                    price = int.tryParse(value) ?? 0;
                  },
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  onChanged: (value) {
                    amount = int.tryParse(value) ?? 0;
                  },
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (name.isNotEmpty) {
                  final docRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userEmail)
                      .collection('medicines')
                      .doc(scannedBarcode);

                  final docSnapshot = await docRef.get();

                  if (docSnapshot.exists) {
                    // Document exists, update the array
                    await docRef.update({
                      'shipments': FieldValue.arrayUnion([
                        {
                          'expire': expire,
                          'cost': cost,
                          'price': price,
                          'amount': amount,
                        },
                      ]),
                    });
                  } else {
                    // Document does not exist, create a new document
                    await docRef.set({
                      'Name': name,
                      'Brand': brand,
                      'Dose': dose,
                      'shipments': [
                        {
                          'expire': expire,
                          'cost': cost,
                          'price': price,
                          'amount': amount,
                        },
                      ],
                    });
                  }

                  Navigator.of(context).pop();
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.black87,
                    ),
                    dropdownColor: Colors.white,
                    items: const [
                      DropdownMenuItem(
                        value: 'category1',
                        child: Text(
                          'Category 1',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'category2',
                        child: Text(
                          'Category 2',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      // Handle category selection
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Sort By',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.black87,
                    ),
                    dropdownColor: Colors.white,
                    items: const [
                      DropdownMenuItem(
                        value: 'name',
                        child: Text(
                          'Name',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'price',
                        child: Text(
                          'Price',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        // Handle sorting selection
                        if (value == 'name') {
                          _sortColumnIndex = 0;
                        } else if (value == 'price') {
                          _sortColumnIndex = 2;
                        }
                        _sortAscending = !_sortAscending;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                dataRowHeight: null, // Set dataRowHeight to null to remove checkboxes
                sortAscending: _sortAscending,
                sortColumnIndex: _sortColumnIndex,
                columnSpacing: 45.0, // Adjust the spacing between columns
                columns: [
                  DataColumn(
                    label: const Text('Name'),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortAscending = ascending;
                        _sortColumnIndex = columnIndex;
                        if (ascending) {
                          _data.sort((a, b) => a['Name'].compareTo(b['Name']));
                        } else {
                          _data.sort((a, b) => b['Name'].compareTo(a['Name']));
                        }
                      });
                    },
                  ),
                  DataColumn(label: const Text('Brand')),
                  DataColumn(label: const Text('Dose')),
                  DataColumn(label: const Text('Quantity')), // Add new column for total amount
                ],
                rows: _data.map(
                      (item) {
                    // Calculate total amount
                    num totalAmount = 0;
                    item['Shipments']?.forEach((shipment) {
                      totalAmount += shipment?['amount'] ?? 0;
                    });

                    return DataRow(
                      cells: [
                        DataCell(
                          GestureDetector(
                            onTap: () {
                              _showShipmentsDialog(item['Shipments']);
                            },
                            child: Text(item['Name']),
                          ),
                        ),
                        DataCell(
                          GestureDetector(
                            onTap: () {
                              _showShipmentsDialog(item['Shipments']);
                            },
                            child: Text(item['Brand']),
                          ),
                        ),
                        DataCell(
                          GestureDetector(
                            onTap: () {
                              _showShipmentsDialog(item['Shipments']);
                            },
                            child: Text('${item['Dose']}'),
                          ),
                        ),
                        DataCell(Text(totalAmount.toString())), // Convert to string
                      ],
                    );
                  },
                ).toList(),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcode,
        child: const Icon(Icons.qr_code_scanner),
      ),
    );

  }
  bool _isExpanded = false;
  Map<String, dynamic>? _selectedRowData;



  void _toggleExpandedState(Map<String, dynamic> rowData) {
    setState(() {
      if (_selectedRowData == rowData) {
        _isExpanded = false;
        _selectedRowData = null;
      } else {
        _isExpanded = true;
        _selectedRowData = rowData;
      }
    });
  }

  void _showShipmentsDialog(List<dynamic> shipments) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Shipments'),
          content: Container(
            width: double.maxFinite,
            height: 300.0, // Adjust the height as needed
            child: ListView.builder(
              itemCount: shipments.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text('Expire: ${shipments[index]['expire']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cost: ${shipments[index]['cost']}'),
                        Text('Price: ${shipments[index]['price']}'),
                        Text('Amount: ${shipments[index]['amount']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }


}

