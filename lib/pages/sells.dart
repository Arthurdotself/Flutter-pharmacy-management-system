import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../backend/functions.dart';

class Sells extends StatefulWidget {
  final String userEmail;
  final String pharmacyId;
  const Sells({Key? key, required this.userEmail, required this.pharmacyId}) : super(key: key);

  @override
  _SellsState createState() => _SellsState();

}

class _SellsState extends State<Sells> with TickerProviderStateMixin {
  String _selectedTimePeriod = 'Today';
  late Future<List<Map<String, dynamic>>> _sellsDataFuture;
  List<dynamic> shipments = []; // Declare shipments list at class level
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    setUserEmail(context);
    super.initState();
    _sellsDataFuture = fetchSellsData();

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FadeTransition(
          opacity: _fadeInAnimation,
          child:  Text(getTranslations()['sells']!),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: DropdownButtonFormField<String>(
                value: _selectedTimePeriod,
                decoration:  InputDecoration(
                  labelText: getTranslations()['time_period']!,
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    String selectedDate = getDateForPeriod(value!);
                    _selectedTimePeriod = value;
                    _sellsDataFuture = fetchSellsData(selectedDate: selectedDate);// Refresh sells data with selected date
                  });
                },
                items: [
                  'Today',
                  'Yesterday',
                  'All', // Add 'All' option
                ].map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period),
                  );
                }).toList(),
              ),
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
                  if (sellsData.isEmpty) {
                    return Center(child: Text(
                        getTranslations()['no_sells_data_found_for']!+"$_selectedTimePeriod"));
                  } else {
                    return ListView.builder(
                      itemCount: sellsData.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> sell = sellsData[index];
                        return FadeTransition(
                          opacity: _fadeInAnimation,
                          child: ListTile(
                            title: Text(sell['productName'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(getTranslations()['price']!+': ${sell['price'] ?? ''}'),
                                Text(getTranslations()['quantity']!+': ${sell['quantity'] ?? ''}'),
                                Text(getTranslations()['seller']!+': ${sell['seller'] ?? ''}'),
                                Text(getTranslations()['expire']!+': ${DateFormat('yyyy-MM-dd').format(DateTime.parse(sell['expire']))}'),
                                Text(getTranslations()['time']!+': ${formatTimestamp(sell['time'])}'),
                              ],
                            ),
                            onTap: () {
                              // Add functionality for tapping on a sold product if needed
                            },
                          ),
                        );
                      },
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     sellscanBarcode(context);
      //   },
      //   child: Icon(Icons.qr_code_scanner),
      // ),

    );
  }
}
