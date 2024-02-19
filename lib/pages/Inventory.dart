import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Inventory extends StatefulWidget {
  final String userEmail;

  const Inventory({Key? key, required this.userEmail}) : super(key: key);

  @override
  _InventoryState createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  bool _sortAscending = true;
  int _sortColumnIndex = 0;

  final List<Map<String, dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    _fetchMedicines();
  }

  Future<void> _fetchMedicines() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userEmail)
        .collection('medicines')
        .get();
    final List<Map<String, dynamic>> newData = [];
    for (final doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.isNotEmpty) {
        final firstField = data.keys.first;
        newData.add({firstField: data[firstField]});
      }
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
          content: Text('Scanned Barcode: $barcodeScanRes'),
          duration: Duration(seconds: 3), // Adjust the duration as needed
        ),
      );

      _showAddMedicineDialog(barcodeScanRes);
    });
  }

  void _showAddMedicineDialog(String scannedBarcode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String brand = '';
        int dose = 0;
        int cost = 0;
        String expire = '';
        String name = '';
        int price = 0;
        int amount = 0;

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
                ),
                TextField(
                  onChanged: (value) {
                    brand = value;
                  },
                  decoration: InputDecoration(labelText: 'Brand'),
                ),
                TextField(
                  onChanged: (value) {
                    dose = int.tryParse(value) ?? 0;
                  },
                  decoration: InputDecoration(labelText: 'Dose'),
                  keyboardType: TextInputType.number,
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
              onPressed: () {
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
                      'medicines': FieldValue.arrayUnion([
                        {
                          'name': name,
                          'brand': brand,
                          'dose': dose,
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
                      'medicines': [
                        {
                          'name': name,
                          'brand': brand,
                          'dose': dose,
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
                sortAscending: _sortAscending,
                sortColumnIndex: _sortColumnIndex,
                columns: [
                  DataColumn(
                    label: const Text('First Field'),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortAscending = ascending;
                        _sortColumnIndex = columnIndex;
                        if (ascending) {
                          _data.sort((a, b) => a.values.first.compareTo(b.values.first));
                        } else {
                          _data.sort((a, b) => b.values.first.compareTo(a.values.first));
                        }
                      });
                    },
                  ),
                ],
                rows: _data.map(
                      (item) => DataRow(
                    cells: [
                      DataCell(Text(item.values.first.toString())),
                    ],
                  ),
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
}
