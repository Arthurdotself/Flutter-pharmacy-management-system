import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../backend/user_provider.dart';
import 'package:intl/intl.dart';

class ExpiringExpiredPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expiring & Expired Items'),
      ),
      body: ExpiringExpiredList(),
    );
  }
}

class ExpiringExpiredList extends StatefulWidget {
  @override
  _ExpiringExpiredListState createState() => _ExpiringExpiredListState();
}

class _ExpiringExpiredListState extends State<ExpiringExpiredList> {
  List<ExpiringExpiredItem> _items = [];

  @override
  void initState() {
    super.initState();
    // Call the function to get expiring items from Firebase Firestore
    _fetchExpiringItems();
  }

  Future<void> _fetchExpiringItems() async {
    try {
      Timestamp timestamp = Timestamp.now();
      DateTime dateTime = timestamp.toDate();
      String formattedDateTime = DateFormat.yMMMMd().add_jms().add_E().format(dateTime);
      // Specify the pharmacyId you want to retrieve expiring items for
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      String pharmacyId = userProvider.PharmacyId;
      // Query the Firestore collection group for expiring items
      QuerySnapshot expiringItemsSnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('medicines')
          .get();

      expiringItemsSnapshot.docs.forEach((doc) {
        print(doc.data());
      });


      // Convert the retrieved documents into ExpiringExpiredItem objects
      List<ExpiringExpiredItem> items = expiringItemsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return ExpiringExpiredItem(
          name: data['name'],
          quantity: data['Brand'],
          expiringDate: (data['expire'] as Timestamp).toDate(),
        );
      }).toList();

      // Update the state with the retrieved items
      setState(() {
        _items = items;
      });
    } catch (error) {
      print('Error fetching expiring items: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return ExpiringExpiredListItem(item: _items[index]);
      },
    );
  }
}

class ExpiringExpiredItem {
  final String name;
  final int quantity;
  final DateTime expiringDate;

  ExpiringExpiredItem({
    required this.name,
    required this.quantity,
    required this.expiringDate,
  });
}


class ExpiringExpiredListItem extends StatelessWidget {
  final ExpiringExpiredItem item;

  ExpiringExpiredListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    Color indicatorColor = Colors.blue.shade50; // Default color
    Duration timeDifference = item.expiringDate.difference(DateTime.now());
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
                'Name: ${item.name}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(height: 8.0),
              Text('Quantity: ${item.quantity}'),
              SizedBox(height: 8.0),
              Text('Expiring Date: ${item.expiringDate.toString()}'),
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
