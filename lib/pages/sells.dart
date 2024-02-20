import 'package:flutter/material.dart';

class Sells extends StatefulWidget {
  const Sells({Key? key}) : super(key: key);

  @override
  _SellsState createState() => _SellsState();
}

class _SellsState extends State<Sells> {
  String _selectedTimePeriod = 'Today';

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
            child: ListView.builder(
              itemCount: 20, // Replace with your actual data count
              itemBuilder: (context, index) {
                // Replace ListTile with your actual UI for displaying each sold product
                return ListTile(
                  title: Text('Product ${index + 1}'),
                  subtitle: Text('Price: \$${(index + 1) * 10}'),
                  trailing: Text('Qty: ${index + 1}'),
                  onTap: () {
                    // Add functionality for tapping on a sold product if needed
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
