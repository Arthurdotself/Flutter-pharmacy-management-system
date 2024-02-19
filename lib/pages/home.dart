import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:tugas1_login/pages/Inventory.dart';
import 'package:tugas1_login/pages/sells.dart';

class Dashbord extends StatefulWidget {
  final String userEmail;

  const Dashbord({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<Dashbord> createState() => _DashbordState();
}
String currentDate = DateTime.now().toString().substring(0, 10);
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
              padding: charts.DatumLegend.defaultCellPadding,
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
                                        await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            String brand = '';
                                            int cost = 0;
                                            String expire = '';
                                            String name = '';
                                            int price = 0;
                                            int amount = 0; // Add amount field

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
                                                      price = int.tryParse(value) ?? 0;
                                                    },
                                                    decoration: InputDecoration(labelText: 'Price'),
                                                    keyboardType: TextInputType.number,
                                                  ),
                                                  TextField(
                                                    onChanged: (value) {
                                                      amount = int.tryParse(value) ?? 0; // Update amount value
                                                    },
                                                    decoration: InputDecoration(labelText: 'Amount'), // Add amount field
                                                    keyboardType: TextInputType.number,
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    if (name.isNotEmpty) {
                                                      await FirebaseFirestore.instance.collection('users').doc(widget.userEmail).collection('medicines').doc(name).set({
                                                        'brand': brand,
                                                        'cost': cost,
                                                        'expire': expire,
                                                        'name': name,
                                                        'price': price,
                                                        'amount': amount, // Include amount in the document
                                                      });
                                                      Navigator.of(context).pop();
                                                    } else {
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
                                      child: Text("    More    "),
                                    )
                                    ,
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
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.userEmail)
                                .collection('sells')
                                .doc(currentDate)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Text("Loading...");
                              } else if (snapshot.hasError) {
                                return Text("Error: ${snapshot.error}");
                              } else {
                                var sellsData = snapshot.data!.data() as Map<String, dynamic>?; // Cast to Map<String, dynamic> or null

                                if (sellsData != null && sellsData.containsKey('data')) {
                                  var dataCount = (sellsData['data'] as List).length;

                                  return Column(
                                    children: [
                                      Text(
                                        "$dataCount Sells",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      SizedBox(height: 15.0),
                                    ],
                                  );
                                } else {
                                  return Text(
                                    "No sells data found",
                                    style: TextStyle(color: Colors.white),
                                  );
                                }
                              }
                            },
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  String name = '';
                                  int dose = 0;
                                  String brand = '';
                                  String expire = '';
                                  String price = '';
                                  String date = DateTime.now().toString();

                                  return AlertDialog(
                                    title: Text("Add Sale"),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          onChanged: (value) {
                                            name = value;
                                          },
                                          decoration: InputDecoration(labelText: 'Name'),
                                        ),
                                        TextField(
                                          onChanged: (value) {
                                            dose = int.tryParse(value) ?? 0;
                                          },
                                          decoration: InputDecoration(labelText: 'Dose'),
                                          keyboardType: TextInputType.number,
                                        ),
                                        TextField(
                                          onChanged: (value) {
                                            brand = value;
                                          },
                                          decoration: InputDecoration(labelText: 'Brand'),
                                        ),
                                        TextField(
                                          onChanged: (value) {
                                            expire = value;
                                          },
                                          decoration: InputDecoration(labelText: 'Expire'),
                                        ),
                                        TextField(
                                          onChanged: (value) {
                                            price = value;
                                          },
                                          decoration: InputDecoration(labelText: 'Price'),
                                        ),
                                        Text(
                                          'Date: $date',
                                          style: TextStyle(fontSize: 12.0),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          if (name.isNotEmpty) {
                                            String currentDate = DateTime.now().toString().substring(0, 10);
                                            CollectionReference sellsCollection = FirebaseFirestore.instance.collection('users').doc(widget.userEmail).collection('sells');
                                            Map<String, dynamic> inputData = {
                                              'name': name,
                                              'dose': dose,
                                              'brand': brand,
                                              'expire': expire,
                                              'price': price,
                                            };
                                            DocumentSnapshot sellsDoc = await sellsCollection.doc(currentDate).get();

                                            if (sellsDoc.exists) {
                                              await sellsCollection.doc(currentDate).update({
                                                'data': FieldValue.arrayUnion([inputData]),
                                              });
                                            } else {
                                              await sellsCollection.doc(currentDate).set({
                                                'data': [inputData],
                                              });
                                            }

                                            Navigator.of(context).pop();
                                          } else {
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
                            child: Text("More"),
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
                            onPressed: () {},
                            child: Text("     More     "),
                          ),
                        ],
                      )
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
                            onPressed: () {},
                            child: Text("     More     "),
                          ),
                        ],
                      )
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
                            onPressed: () {},
                            child: Text("     More     "),
                          ),
                        ],
                      )
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
                            onPressed: () {},
                            child: Text("     More     "),
                          ),
                        ],
                      )
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

      List<CounterData> data = [];

      sellsSnapshot.docs.forEach((doc) {
        Map<String, dynamic>? dataMap = doc.data() as Map<String, dynamic>?;

        // Get the 'data' array from the document
        List<dynamic>? dataArray = dataMap?['data'];

        // Calculate the total count of items in the 'data' array
        int count = dataArray?.length ?? 0;

        data.add(CounterData(count));
      });

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
                  builder: (context) => const Inventory(userEmail: 'admin@pms.com',),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Sells'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Sells(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Calender'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_alt_outlined),
            title: const Text('Notes'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
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
