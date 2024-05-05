import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:tugas1_login/backend/functions.dart';

class Inventory extends StatefulWidget {
  const Inventory({Key? key}) : super(key: key);

  @override
  _InventoryState createState() => _InventoryState();
}
String _pharmacyName = '';

class _InventoryState extends State<Inventory> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredData = [];
  late Stream<List<Map<String, dynamic>>> _medicinesStream;
  bool _showFilteredData = false;

  @override
  void initState() {
    super.initState();
    _medicinesStream = fetchMedicinesStream();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  bool _sortAscending = true;
  int _sortColumnIndex = 0;

  final List<Map<String, dynamic>> _data = [];

  Stream<List<Map<String, dynamic>>> fetchMedicinesStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .snapshots()
        .asyncMap((userSnapshot) async {
      final pharmacyId = userSnapshot['pharmacyId'];

      final pharmacySnapshot =
      await FirebaseFirestore.instance.collection('pharmacies').doc(pharmacyId).get();
      if (pharmacySnapshot.exists) {
        setState(() {
          _pharmacyName = pharmacySnapshot['name'];
        });
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('medicines')
          .get();

      final List<Map<String, dynamic>> newData = [];

      for (var doc in querySnapshot.docs) {
        final id = doc.id;
        final data = doc.data();
        final name = data['Name'] ?? '';
        final dose = data['Dose'] ?? '';
        final brand = data['Brand'] ?? '';
        final shipments = data['shipments'] ?? [];

        final formattedShipments = shipments.map((shipment) {
          final Timestamp expireTimestamp = shipment['expire'];
          final DateTime expireDate = expireTimestamp.toDate();
          final formattedExpireDate = DateFormat('dd/MM/yyyy').format(expireDate);

          return {
            ...shipment,
            'expire': formattedExpireDate,
          };
        }).toList();

        newData.add({
          'id': id,
          'Name': name,
          'Dose': dose,
          'Brand': brand,
          'Shipments': formattedShipments,
        });
      }

      return newData;
    });
  }

  Future<void> _scanBarcode() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
      '#ff6666',
      'Cancel',
      true,
      ScanMode.BARCODE,
    );

    if (!mounted) return;

    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned Barcode: $barcodeScanRes $_pharmacyName'),
          duration: const Duration(seconds: 3),
        ),
      );

      _showAddMedicineDialog(barcodeScanRes);
    });
  }

  void _showAddMedicineDialog(String scannedBarcode) async {
    String brand = '';
    int dose = 0;
    int cost = 0;
    Timestamp? expire;

    String name = '';
    int price = 0;
    int amount = 0;

    final docRef = FirebaseFirestore.instance.collection('pharmacies').doc(pharmacyId).collection('medicines').doc(scannedBarcode);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      name = data['Name'] ?? '';
      brand = data['Brand'] ?? '';
      dose = data['Dose'] ?? 0;
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
                  TextButton(
                    onPressed: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(DateTime.now().year - 5),
                        lastDate: DateTime(DateTime.now().year + 5),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          expire = Timestamp.fromMillisecondsSinceEpoch(selectedDate.millisecondsSinceEpoch);
                        });
                      }
                    },
                    child: Text(
                      expire != null ? DateFormat('yyyy-MM-dd').format(expire!.toDate()) : 'Select Date',
                    ),
                  ),
                  TextField(
                    onChanged: (value) {
                      cost = int.tryParse(value) ?? 0;
                    },
                    decoration: const InputDecoration(labelText: 'cost'),
                    keyboardType: TextInputType.number,
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
                  if (name.isNotEmpty && expire != null) {
                    final pharmacySnapshot = await FirebaseFirestore.instance.collection('users').doc(userEmail).get();
                    final pharmacyId = pharmacySnapshot['pharmacyId'];

                    final docRef = FirebaseFirestore.instance.collection('pharmacies').doc(pharmacyId).collection('medicines').doc(scannedBarcode);

                    final docSnapshot = await docRef.get();

                    if (docSnapshot.exists) {
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
          child: Text(getTranslations()['inventory']!+' - $_pharmacyName'),
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
                controller: _searchController,
                onChanged: _filterData,
                decoration: InputDecoration(
                  hintText: getTranslations()['search']!,
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _medicinesStream,
              builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  if (_showFilteredData) {
                    _filteredData = _data.where((item) {
                      final name = item['Name'].toLowerCase();
                      final brand = item['Brand'].toLowerCase();
                      final dose = item['Dose'].toString().toLowerCase();
                      return name.contains(_searchController.text.toLowerCase()) ||
                          brand.contains(_searchController.text.toLowerCase()) ||
                          dose.contains(_searchController.text.toLowerCase());
                    }).toList();
                  } else {
                    _data.clear(); // Clear existing data
                    _data.addAll(snapshot.data!); // Add new data from the snapshot
                    _filteredData = List.from(_data); // Show all data initially
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: FadeTransition(
                      opacity: _fadeInAnimation,
                      child: DataTable(
                        dataRowHeight: null,
                        sortAscending: _sortAscending,
                        sortColumnIndex: _sortColumnIndex,
                        columnSpacing: 45.0,
                        columns: [
                          DataColumn(
                            label: Text(getTranslations()['name']!),
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                _sortAscending = ascending;
                                _sortColumnIndex = columnIndex;
                                if (ascending) {
                                  _filteredData.sort((a, b) => a['Name'].compareTo(b['Name']));
                                } else {
                                  _filteredData.sort((a, b) => b['Name'].compareTo(a['Name']));
                                }
                              });
                            },
                          ),
                          DataColumn(label: Text(getTranslations()['brand']!)),
                          DataColumn(label: Text(getTranslations()['dose']!)),
                          DataColumn(label: Text(getTranslations()['quantity']!)),
                        ],
                        rows: _filteredData.map((item) {
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
                              DataCell(Text(totalAmount.toString())),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }
              },
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

  void _filterData(String query) {
    if (query.isNotEmpty) {
      setState(() {
        _showFilteredData = true;
      });
    } else {
      setState(() {
        _showFilteredData = false;
      });
    }
    setState(() {
      _filteredData = _data.where((item) {
        final name = item['Name'].toLowerCase();
        final brand = item['Brand'].toLowerCase();
        final dose = item['Dose'].toString().toLowerCase();
        return name.contains(query.toLowerCase()) ||
            brand.contains(query.toLowerCase()) ||
            dose.contains(query.toLowerCase());
      }).toList();
    });
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
              height: 300.0,
              child: ListView.builder(
                itemCount: shipments.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text(getTranslations()['expire']! + ': ${shipments[index]['expire']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(getTranslations()['cost']! + ': ${shipments[index]['cost']}'),
                          Text(getTranslations()['price']! + ': ${shipments[index]['price']}'),
                          Text(getTranslations()['amount']! + ': ${shipments[index]['amount']}'),
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
