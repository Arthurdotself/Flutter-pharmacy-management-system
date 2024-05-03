import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../backend/functions.dart';

class ExpiringExpiredPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslations()['expired_medicines']!),
      ),
      body: AnimatedExpiredMedicinesList(),
    );
  }
}

class AnimatedExpiredMedicinesList extends StatefulWidget {
  @override
  _AnimatedExpiredMedicinesListState createState() => _AnimatedExpiredMedicinesListState();
}

class _AnimatedExpiredMedicinesListState extends State<AnimatedExpiredMedicinesList> {
  late List<Map<String, dynamic>> _expiredMedicines;

  @override
  void initState() {
    super.initState();
    // Initialize with empty list
    _expiredMedicines = [];
    // Call the function to get expired medicines from Firebase Firestore
    _fetchExpiredMedicines();
  }

  Future<void> _fetchExpiredMedicines() async {
    try {
      // Query the Firestore collection for expired medicines
      QuerySnapshot expiredMedicinesSnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('medicines')
          .where('shipments', isLessThanOrEqualTo: [
        {'expire': Timestamp.now()}
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
        return AnimatedExpiredMedicineListItem(
          medicine: _expiredMedicines[index],
          delay: index * 0.1,
        );
      },
    );
  }
}

class AnimatedExpiredMedicineListItem extends StatefulWidget {
  final Map<String, dynamic> medicine;
  final double delay;

  AnimatedExpiredMedicineListItem({required this.medicine, required this.delay});

  @override
  _AnimatedExpiredMedicineListItemState createState() => _AnimatedExpiredMedicineListItemState();
}

class _AnimatedExpiredMedicineListItemState extends State<AnimatedExpiredMedicineListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
      // Add delay to animation
      value: 0.1,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    // Start the animation
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: _buildMedicineInfo(),
      ),
    );
  }

  Widget _buildMedicineInfo() {
    List<dynamic> shipments = widget.medicine['shipments'];
    List<DateTime> expiryDates = [];
    for (var shipment in shipments) {
      DateTime expiryDate = (shipment['expire'] as Timestamp).toDate();
      expiryDates.add(expiryDate);
    }
    Color indicatorColor = Colors.green; // Default color
    DateTime earliestExpiryDate = expiryDates.reduce((a, b) => a.isBefore(b) ? a : b);
    Duration timeDifference = earliestExpiryDate.difference(DateTime.now());
    if (timeDifference.inDays <= 30 && timeDifference.inDays >= 0) {
      indicatorColor = Colors.orange; // Change color to orange if expiring soon
    } else if (timeDifference.isNegative) {
      indicatorColor = Colors.red; // Change color to red if already expired
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getTranslations()['name']!+': ${widget.medicine['Name']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            SizedBox(height: 8.0),
            Text(getTranslations()['quantity']!+': ${widget.medicine['quantity']}'),
            SizedBox(height: 8.0),
            Text(getTranslations()['expire']!+': ${DateFormat.yMMMMd().format(earliestExpiryDate)}'),
            SizedBox(height: 8.0),
            if (timeDifference.inDays >= 0) Text('${getTranslations()['expiring_after']}: ${timeDifference.inDays} ${getTranslations()['days']}'),

            if (timeDifference.isNegative) Text(getTranslations()['expired_since']!+': ${timeDifference.inDays.abs()} ${getTranslations()['days']}'),
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
