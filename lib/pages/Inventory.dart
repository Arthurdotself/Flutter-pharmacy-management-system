import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:tugas1_login/backend/functions.dart';

class Inventory extends StatefulWidget {
  const Inventory({Key? key}) : super(key: key);

  @override
  _InventoryState createState() => _InventoryState();
}

String _pharmacyName = '';
late Timer _timer;

class _InventoryState extends State<Inventory> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  void _fetchAndUpdateMedicines() {
    _fetchMedicines(); // Fetch medicines from Firebase and update _data
    setState(() {}); // Update the UI
  }

  @override
  void initState() {
    super.initState();
    _fetchMedicines();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start the timer when the widget is initialized
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer t) {
      _fetchAndUpdateMedicines(); // Call the function to fetch and update medicines
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    super.dispose();
    // Cancel the timer when the widget is disposed to prevent memory leaks
    _timer.cancel();
    _animationController.dispose();
  }

  bool _sortAscending = true;
  int _sortColumnIndex = 0;

  final List<Map<String, dynamic>> _data = [];

  Future<void> _fetchMedicines() async {
    // Fetch pharmacyId from user document
    final userDataSnapshot = await FirebaseFirestore.instance.collection('users').doc(userEmail).get();
    final pharmacyId = userDataSnapshot['pharmacyId'];

    // Fetch pharmacy name
    final pharmacySnapshot = await FirebaseFirestore.instance.collection('pharmacies').doc(pharmacyId).get();
    if (pharmacySnapshot.exists) {
      setState(() {
        _pharmacyName = pharmacySnapshot['name'];
      });
    }

    // Fetch all medicines for the pharmacyId
    final querySnapshot = await FirebaseFirestore.instance.collection('pharmacies').doc(pharmacyId).collection('medicines').get();

    final List<Map<String, dynamic>> newData = [];

    for (var doc in querySnapshot.docs) {
      final id = doc.id;
      final data = doc.data();
      final name = data['Name'] ?? '';
      final dose = data['Dose'] ?? '';
      final brand = data['Brand'] ?? '';
      final shipments = data['shipments'] ?? [];

      newData.add({
        'id': id,
        'Name': name,
        'Dose': dose,
        'Brand': brand,
        'Shipments': shipments,
      });
    }

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
          content: Text('Scanned Barcode: $barcodeScanRes $_pharmacyName'),
          duration: const Duration(seconds: 3), // Adjust the duration as needed
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

    final docRef = FirebaseFirestore.instance.collection('pharmacies').doc(pharmacyId).collection('medicines').doc(scannedBarcode);

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
        return FadeTransition(
          opacity: _fadeInAnimation,
          child: AlertDialog(
            title: const Text("Add Medicine"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) {
                      name = value;
                    },
                    decoration: const InputDecoration(labelText: 'Name'),
                    controller: TextEditingController(text: name),
                  ),
                  TextField(
                    onChanged: (value) {
                      brand = value;
                    },
                    decoration: const InputDecoration(labelText: 'Brand'),
                    controller: TextEditingController(text: brand),
                  ),
                  TextField(
                    onChanged: (value) {
                      dose = int.tryParse(value) ?? 0;
                    },
                    decoration: const InputDecoration(labelText: 'Dose'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: dose.toString()),
                  ),
                  TextField(
                    onChanged: (value) {
                      expire = value;
                    },
                    decoration: const InputDecoration(labelText: 'Expire'),
                  ),
                  TextField(
                    onChanged: (value) {
                      price = int.tryParse(value) ?? 0;
                    },
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    onChanged: (value) {
                      amount = int.tryParse(value) ?? 0;
                    },
                    decoration: const InputDecoration(labelText: 'Amount'),
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
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (name.isNotEmpty) {
                    final pharmacySnapshot =
                    await FirebaseFirestore.instance.collection('users').doc(userEmail).get();

                    final pharmacyId = pharmacySnapshot['pharmacyId'];

                    final docRef = FirebaseFirestore.instance.collection('pharmacies').doc(pharmacyId).collection('medicines').doc(scannedBarcode);

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
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FadeTransition(
          opacity: _fadeInAnimation,
          child: Text('Inventory - $_pharmacyName'),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FadeTransition(
              opacity: _fadeInAnimation,
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeInAnimation,
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
                          value: 'category0',
                          child: Text(
                            'All',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'category1',
                          child: Text(
                            'Prescription Medications',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'category2',
                          child: Text(
                            'Over-the-Counter (OTC) Medications',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'category3',
                          child: Text(
                            'Health and Wellness Products',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'category4',
                          child: Text(
                            'Personal Care Products',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'category5',
                          child: Text(
                            'Medical Devices and Supplies',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'category6',
                          child: Text(
                            'Home Health Care Equipment',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'category7',
                          child: Text(
                            'Baby and Child Care Products',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'category8',
                          child: Text(
                            'Diet and Nutrition Products',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'category9',
                          child: Text(
                            'Smoking Cessation Aids',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'category10',
                          child: Text(
                            'Incontinence Products',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'category11',
                          child: Text(
                            'Pet Medications and Supplies',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        // Handle category selection
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 70.0),
                // Expanded(
                //   child: FadeTransition(
                //     opacity: _fadeInAnimation,
                //     child: DropdownButtonFormField<String>(
                //       decoration: const InputDecoration(
                //         labelText: 'Sort By',
                //         border: InputBorder.none,
                //       ),
                //       style: const TextStyle(
                //         fontSize: 16.0,
                //         color: Colors.black87,
                //       ),
                //       dropdownColor: Colors.white,
                //       items: const [
                //         DropdownMenuItem(
                //           value: 'name',
                //           child: Text(
                //             'Name',
                //             style: TextStyle(color: Colors.black87),
                //           ),
                //         ),
                //         // DropdownMenuItem(
                //         //   value: 'price',
                //         //   child: Text(
                //         //     'Price',
                //         //     style: TextStyle(color: Colors.black87),
                //         //   ),
                //         // ),
                //       ],
                //       onChanged: (value) {
                //         setState(() {
                //           // Handle sorting selection
                //           if (value == 'name') {
                //             _sortColumnIndex = 0;
                //           } else if (value == 'price') {
                //             _sortColumnIndex = 2;
                //           }
                //           _sortAscending = !_sortAscending;
                //         });
                //       },
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: FadeTransition(
                opacity: _fadeInAnimation,
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
                    const DataColumn(label: Text('Brand')),
                    const DataColumn(label: Text('Dose')),
                    const DataColumn(label: Text('Quantity')), // Add new column for total amount
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
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcode,
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  void _showShipmentsDialog(List<dynamic> shipments) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FadeTransition(
          opacity: _fadeInAnimation,
          child: AlertDialog(
            title: const Text('Shipments'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.0, // Adjust the height as needed
              child: ListView.builder(
                itemCount: shipments.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
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
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
