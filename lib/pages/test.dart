import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../backend/user_provider.dart';

class TestNewThingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expired Medicines'),
      ),
      body: ExpiredMedicinesList(),
    );
  }
}

class ExpiredMedicinesList extends StatefulWidget {
  @override
  _ExpiredMedicinesListState createState() => _ExpiredMedicinesListState();
}

class _ExpiredMedicinesListState extends State<ExpiredMedicinesList> {
  List<Map<String, dynamic>> _expiredMedicines = [];

  @override
  void initState() {
    super.initState();
    // Call the function to get expired medicines from Firebase Firestore
    _fetchExpiredMedicines();
  }

  Future<void> _fetchExpiredMedicines() async {
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    String pharmacyId = userProvider.PharmacyId;
    try {
      // Query the Firestore collection for expired medicines
      QuerySnapshot expiredMedicinesSnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('medicines')
          .where('shipments', isLessThanOrEqualTo: [
        {'expire': Timestamp.now()} // This ensures that at least one shipment has an expire field greater than or equal to current time
      ])
          .get();

      // Convert the retrieved documents into a list of maps
      List<Map<String, dynamic>> expiredMedicines = expiredMedicinesSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      print('Expired Medicines: $expiredMedicines');

      // Update the state with the retrieved expired medicines
      setState(() {
        _expiredMedicines = expiredMedicines;
      });
    } catch (error) {
      print('Error fetching expired medicines: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _expiredMedicines.length,
      itemBuilder: (context, index) {
        return ExpiredMedicineListItem(medicine: _expiredMedicines[index]);
      },
    );
  }
}

class ExpiredMedicineListItem extends StatelessWidget {
  final Map<String, dynamic> medicine;

  ExpiredMedicineListItem({required this.medicine});

  @override
  Widget build(BuildContext context) {
    List<dynamic> shipments = medicine['shipments'];
    List<DateTime> expiryDates = [];

    for (var shipment in shipments) {
      DateTime expiryDate = (shipment['expire'] as Timestamp).toDate();
      expiryDates.add(expiryDate);
    }

    Color indicatorColor = Colors.blue.shade50; // Default color
    DateTime earliestExpiryDate = expiryDates.reduce((a, b) => a.isBefore(b) ? a : b);
    Duration timeDifference = earliestExpiryDate.difference(DateTime.now());
    if (timeDifference.inDays <= 30 && timeDifference.inDays >= 0) {
      indicatorColor = Colors.orange; // Change color to orange if expiring soon
    } else if (timeDifference.isNegative) {
      indicatorColor = Colors.red; // Change color to red if already expired
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name: ${medicine['Name']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(height: 8.0),
              Text('Quantity: ${medicine['quantity']}'),
              SizedBox(height: 8.0),
              Text('Expiring Date: ${DateFormat.yMMMMd().format(earliestExpiryDate)}'),
              SizedBox(height: 8.0),
              if (timeDifference.inDays >= 0)
                Text('Expiring After ${timeDifference.inDays} Days'),
              if (timeDifference.isNegative)
                Text('Expired since ${timeDifference.inDays.abs()} Days'),
            ],
          ),
          Container(
            width: 20,
            height: 110,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
        ],
      ),
    );
  }
}
