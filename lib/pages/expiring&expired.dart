import 'package:flutter/material.dart';

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
    // Example data, replace with your actual data
    _items = [
      ExpiringExpiredItem(
        name: 'Item 1',
        quantity: 10,
        expiringDate: DateTime.now().add(Duration(days: 25)),
      ),
      ExpiringExpiredItem(
        name: 'Item 2',
        quantity: 5,
        expiringDate: DateTime.now().subtract(Duration(days: 5)),
      ),
    ];
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

