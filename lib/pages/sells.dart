import 'package:flutter/material.dart';
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

      QuerySnapshot sellsSnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('sells')
          .where('date', isEqualTo: selectedDate)
          .get();

      List<Map<String, dynamic>> data = [];

      for (var doc in sellsSnapshot.docs) {
        data.add(doc.data() as Map<String, dynamic>);
      }

      return data;
    } catch (error) {
      print("Error fetching sells data: $error");
      return [];
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
    );
  }
}
