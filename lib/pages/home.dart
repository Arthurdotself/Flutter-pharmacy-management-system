import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:tugas1_login/pages/Inventory.dart';

class Dashbord extends StatefulWidget {
  final String userEmail;

  const Dashbord({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<Dashbord> createState() => _DashbordState();
}

class _DashbordState extends State<Dashbord> {
  final List<String> gridLabels = [
    'medicines',
    'Today Sell',
    'فواتير الشراء',
    'check patient profile',
    'Expiring',
    'Expired',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: const NavBar(),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 9,),
          Expanded(
            child: GridView.count(
              padding: charts.DatumLegend.defaultCellPadding ,
              crossAxisCount: 3,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              children: List.generate(6, (index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(22.0),
                  child: Container(
                    color: Colors.blue,
                    child: Center(
                      child: index == 0
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(widget.userEmail).collection('medicines').get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Text("Loading...");
                              } else if (snapshot.hasError) {
                                return Text("Error: ${snapshot.error}");
                              } else {
                                var medicinesCount = snapshot.data!.docs.length;
                                return Column(
                                  children: [
                                    Text("$medicinesCount Medicines", style: TextStyle(color: Colors.white)),
                                    SizedBox(height: 15.0),

                                    ElevatedButton(
                                      onPressed: () async {
                                        // Open a pop-up dialog with input fields
                                        await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            // Variables to store input values
                                            String brand = '';
                                            int cost = 0;
                                            String expire = '';
                                            String name = '';
                                            int price = 0;

                                            return AlertDialog(
                                              title: Text("Add Medicine"),
                                              content: Column(
                                                children: [
                                                  TextField(
                                                    onChanged: (value) {
                                                      brand = value;
                                                    },
                                                    decoration: InputDecoration(labelText: 'Brand'),
                                                  ),
                                                  TextField(
                                                    onChanged: (value) {
                                                      // Validate and parse the cost as an integer
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
                                                      name = value;
                                                    },
                                                    decoration: InputDecoration(labelText: 'Name'),
                                                  ),
                                                  TextField(
                                                    onChanged: (value) {
                                                      // Validate and parse the price as an integer
                                                      price = int.tryParse(value) ?? 0;
                                                    },
                                                    decoration: InputDecoration(labelText: 'Price'),
                                                    keyboardType: TextInputType.number,
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    // Close the dialog
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    if (name.isNotEmpty) {
                                                      // Add a new medicine with name as document ID
                                                      await FirebaseFirestore.instance.collection('users').doc(widget.userEmail).collection('medicines').doc(name).set({
                                                        'brand': brand,
                                                        'cost': cost,
                                                        'expire': expire,
                                                        'name': name,
                                                        'price': price,
                                                        'amount': 0,
                                                        // Add more fields as needed
                                                      });
                                                      // Close the dialog
                                                      Navigator.of(context).pop();
                                                    } else {
                                                      // Show an error message if name is empty
                                                      // You can customize this part based on your needs
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return AlertDialog(
                                                            title: Text("Error"),
                                                            content: Text("Name cannot be empty."),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(context).pop();
                                                                },
                                                                child: Text("OK"),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    }
                                                  },
                                                  child: Text("Add"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Text("     More     "),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      )
                          : index == 1
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.userEmail)
                                .collection('sells')
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text("Loading...");
                              } else if (snapshot.hasError) {
                                return Text(
                                    "Error: ${snapshot.error}");
                              } else {
                                var sellsCount =
                                    snapshot.data!.docs.length;
                                return Column(
                                  children: [
                                    Text(
                                      "$sellsCount Sells",
                                      style: TextStyle(
                                          color: Colors.white),
                                    ),
                                    SizedBox(height: 15.0),
                                    ElevatedButton(
                                      onPressed: () async {
                                        // Open a pop-up dialog with input fields
                                        await showDialog(
                                          context: context,
                                          builder: (BuildContext
                                          context) {
                                            // Variables to store input values
                                            String name = '';
                                            int pharmacist = 0;
                                            String price = '';
                                            // Get current date and time
                                            String date =
                                            DateTime.now()
                                                .toString();

                                            return AlertDialog(
                                              title: Text(
                                                  "Add Sale"),
                                              content: Column(
                                                children: [
                                                  TextField(
                                                    onChanged:
                                                        (value) {
                                                      name =
                                                          value;
                                                    },
                                                    decoration: InputDecoration(
                                                        labelText:
                                                        'Name'),
                                                  ),
                                                  TextField(
                                                    onChanged:
                                                        (value) {
                                                      // Validate and parse the pharmacist as an integer
                                                      pharmacist =
                                                          int.tryParse(
                                                              value) ??
                                                              0;
                                                    },
                                                    decoration: InputDecoration(
                                                        labelText:
                                                        'Pharmacist'),
                                                    keyboardType:
                                                    TextInputType
                                                        .number,
                                                  ),
                                                  TextField(
                                                    onChanged:
                                                        (value) {
                                                      price =
                                                          value;
                                                    },
                                                    decoration: InputDecoration(
                                                        labelText:
                                                        'Price'),
                                                  ),
                                                  // Display the current date and time
                                                  Text(
                                                    'Date: $date',
                                                    style: TextStyle(
                                                        fontSize:
                                                        12.0),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    // Close the dialog
                                                    Navigator.of(
                                                        context)
                                                        .pop();
                                                  },
                                                  child:
                                                  Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () async {
                                                    if (name
                                                        .isNotEmpty) {
                                                      // Add a new sale
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                          'users')
                                                          .doc(widget
                                                          .userEmail)
                                                          .collection(
                                                          'sells')
                                                          .add({
                                                        'name':
                                                        name,
                                                        'pharmacist':
                                                        pharmacist,
                                                        'price':
                                                        price,
                                                        'date':
                                                        date,
                                                        'amount': 0,
                                                        // Add more fields as needed
                                                      });
                                                      // Close the dialog
                                                      Navigator.of(
                                                          context)
                                                          .pop();
                                                    } else {
                                                      // Show an error message if name is empty
                                                      // You can customize this part based on your needs
                                                      showDialog(
                                                        context:
                                                        context,
                                                        builder:
                                                            (BuildContext
                                                        context) {
                                                          return AlertDialog(
                                                            title:
                                                            Text(
                                                                "Error"),
                                                            content:
                                                            Text(
                                                                "Name cannot be empty."),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () {
                                                                  Navigator.of(context).pop();
                                                                },
                                                                child:
                                                                Text("OK"),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    }
                                                  },
                                                  child:
                                                  Text("Add"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Text("     More     "),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      )
                          : index == 2
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Purchase invoices',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 15.0),
                          ElevatedButton(
                            onPressed: () {
                              // Add your button functionality here
                            },
                            child: Text("     More     "),
                          ),
                        ],
                      )


// ========================================================================================

                          : index == 3
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Patient profile',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 15.0),
                          ElevatedButton(
                            onPressed: () {
                              // Add your button functionality here
                            },
                            child: Text("     More     "),
                          ),
                        ],
                      )

// ========================================================================================
                          : index == 4
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Expiring',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 15.0),
                          ElevatedButton(
                            onPressed: () {
                              // Add your button functionality here
                            },
                            child: Text("     More     "),
                          ),
                        ],
                      )
// ========================================================================================

                          : index == 5
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Expired',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 15.0),
                          ElevatedButton(
                            onPressed: () {
                              // Add your button functionality here
                            },
                            child: Text("     More     "),
                          ),
                        ],
                      )

// ========================================================================================

                          : Text(
                        gridLabels[index],
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: YourBarChart(userEmail: widget.userEmail),
          ),
        ],
      ),
    );
  }
}

class YourBarChart extends StatefulWidget {
  final String userEmail;

  const YourBarChart({Key? key, required this.userEmail}) : super(key: key);

  @override
  _YourBarChartState createState() => _YourBarChartState();
}

class _YourBarChartState extends State<YourBarChart> {
  List<CounterData> dailySales = [];

  @override
  void initState() {
    super.initState();
    fetchSalesData();
  }

  Future<void> fetchSalesData() async {
    try {
      QuerySnapshot sellsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userEmail)
          .collection('sells')
          .get();

      List<CounterData> data = sellsSnapshot.docs.map((doc) {
        Map<String, dynamic>? dataMap = doc.data() as Map<String, dynamic>?; // Ensure correct type
        // Use null-aware access operator and provide a default value if 'amount' is null
        int count = dataMap?['amount'] ?? 0;
        return CounterData(count);
      }).toList();

      setState(() {
        dailySales = data;
      });
    } catch (error) {
      print("Error fetching sales data: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: dailySales.isNotEmpty
          ? charts.BarChart(
        [
          charts.Series<CounterData, String>(
            id: 'DailySells',
            data: dailySales,
            // Use string interpolation to concatenate the string and integer
            domainFn: (_, index) => 'Day ${index! + 1}',
            measureFn: (sales, _) => sales.count,
            colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          ),
        ],
        animate: true,
        barGroupingType: charts.BarGroupingType.grouped,
        behaviors: [
          charts.SeriesLegend(
            position: charts.BehaviorPosition.bottom,
            showMeasures: true,
          ),
        ],
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class CounterData {
  final int count;

  CounterData(this.count);
}

class NavBar extends StatelessWidget {
  const NavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
        children: [
          const DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTtuphMb4mq-EcVWhMVT8FCkv5dqZGgvn_QiA&usqp=CAU',
                  ),
                  radius: 30,
                ),
                SizedBox(height: 10),
                Text(
                  'Belal',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'belal@gmail.com',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Inventory'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Inventory(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Sells'),
            onTap: () {
              Navigator.pop(context);
              //Navigator.push(
             //   context,
              //  MaterialPageRoute(
              //    builder: (context) => const Sells(),
              //  ),
              //);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Calender'),
            onTap: () {
              Navigator.pop(context);
             // Navigator.push(
              //  context,
               // MaterialPageRoute(
              //    builder: (context) => const Calender(),
              //  ),
             // );
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_alt_outlined),
            title: const Text('Notes'),
            onTap: () {
              Navigator.pop(context);
             // Navigator.push(
              //  context,
              //  MaterialPageRoute(
                 // builder: (context) => const Notes(),
             //   ),
             // );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const Settings(),
              //   ),
              // );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('LogOut'),
            leading: const Icon(Icons.exit_to_app),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
