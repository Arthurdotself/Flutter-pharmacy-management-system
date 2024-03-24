import 'package:flutter/material.dart';

class PurchaseInvoices extends StatefulWidget {
  @override
  _PurchaseInvoicesState createState() => _PurchaseInvoicesState();
}

class _PurchaseInvoicesState extends State<PurchaseInvoices> {
  List<Map<String, dynamic>> invoices = [
    {'id': 1, 'date': 'January 1, 2023', 'totalPrice': 100.0},
    {'id': 2, 'date': 'January 2, 2023', 'totalPrice': 150.0},
    // Add more invoices as needed
  ];

  List<Map<String, dynamic>> filteredInvoices = [];

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredInvoices = invoices;
  }

  void _searchInvoices(String query) {
    setState(() {
      filteredInvoices = invoices
          .where((invoice) =>
      invoice['date'].toLowerCase().contains(query.toLowerCase()) ||
          invoice['id'].toString().contains(query.toLowerCase()) ||
          invoice['totalPrice']
              .toString()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _showInvoiceDetails(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invoice #${invoice['id']} Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date: ${invoice['date'] ?? 'N/A'}'),
              Text('Total Price: \$${invoice['totalPrice'] ?? 'N/A'}'),
              Text('Products:'),
              if (invoice['products'] != null)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: invoice['products'].length,
                  itemBuilder: (context, index) {
                    var product = invoice['products'][index];
                    return ListTile(
                      title: Text(product['name'] ?? 'N/A'),
                      subtitle: Text('Price: \$${product['price'] ?? 'N/A'}'),
                    );
                  },
                ),
              if (invoice['products'] == null || invoice['products'].isEmpty)
                Text('Product 1 - \$30 - Quantity:4\nProduct 2 - \$40 - Quantity:2\nProduct 3 - \$30 - Quantity:6\n'),
              // Add more details as needed
            ],
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Invoices'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by date, ID, or total price',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _searchInvoices(value);
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredInvoices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Invoice #${filteredInvoices[index]['id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${filteredInvoices[index]['date']}'),
                      Text('Total Price: \$${filteredInvoices[index]['totalPrice']}'),
                      // Add more details as needed
                    ],
                  ),
                  onTap: () {
                    _showInvoiceDetails(filteredInvoices[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
