import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:tugas1_login/pages/Inventory.dart';
import 'package:tugas1_login/pages/sells.dart';

import 'notes.dart';

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
        backgroundColor: Colors.blue[50],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: NavBar(userEmail: widget.userEmail),
      backgroundColor: Colors.blue[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 40,
          margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
          child: Text("Pharmacist Dashboard",style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),),
          Expanded(
            child: GridView.count(
              padding: charts.DatumLegend.defaultCellPadding,
              crossAxisCount: 3,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              children: List.generate(6, (index) {
                Color? gridColor; // Default color
                if (index == 0) {
                  gridColor = Colors.blue[200]; // Change color for the first grid
                }
                if (index == 1) {
                  gridColor = Colors.indigo[200]; // Change color for the first grid
                }
                if (index == 2) {
                  gridColor = Colors.blue[200]; // Change color for the first grid
                }
                if (index == 3) {
                  gridColor = Colors.indigo[200]; // Change color for the first grid
                }
                if (index == 4) {
                  gridColor = Colors.blue[200]; // Change color for the first grid
                }
                if (index == 5) {
                  gridColor = Colors.indigo[200]; // Change color for the first grid
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(22.0),
                  child: Container(
                    color: gridColor,
                    child: Center(
                      child: index == 0
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(widget.userEmail).collection('medicines').get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text("Loading...");
                              } else if (snapshot.hasError) {
                                return Text("Error: ${snapshot.error}");
                              } else {
                                var medicinesCount = snapshot.data!.docs.length;
                                return Column(
                                  children: [
                                    Text(
                                      "$medicinesCount\nMedicines",
                                      style: const TextStyle(color: Colors.white, fontSize: 19.1),
                                    ),
                                    const SizedBox(height: 5.0),
                                    ElevatedButton(
                                      onPressed: ()  {
                                        // Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const Inventory(userEmail: 'admin@pms.com',pharmacyId:'KYFUz7GO7IHV8tsLAYGF'),
                                          ),
                                        );
                                      },
                                      child: const Text("    More    "),
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
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.userEmail)
                                .collection('sells')
                                .doc(currentDate)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text("Loading...");
                              } else if (snapshot.hasError) {
                                return Text("Error: ${snapshot.error}");
                              } else {
                                var sellsData = snapshot.data!.data() as Map<String, dynamic>?; // Cast to Map<String, dynamic> or null

                                if (sellsData != null && sellsData.containsKey('data')) {
                                  var dataCount = (sellsData['data'] as List).length;

                                  return Column(
                                    children: [
                                      Text(
                                        "$dataCount\nSells",
                                        style: const TextStyle(color: Colors.white, fontSize: 19.1),
                                      ),
                                      const SizedBox(height: 5.0),
                                    ],
                                  );
                                } else {
                                  return const Text(
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
                                    title: const Text("Add Sale"),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          onChanged: (value) {
                                            name = value;
                                          },
                                          decoration: const InputDecoration(labelText: 'Name'),
                                        ),
                                        TextField(
                                          onChanged: (value) {
                                            dose = int.tryParse(value) ?? 0;
                                          },
                                          decoration: const InputDecoration(labelText: 'Dose'),
                                          keyboardType: TextInputType.number,
                                        ),
                                        TextField(
                                          onChanged: (value) {
                                            brand = value;
                                          },
                                          decoration: const InputDecoration(labelText: 'Brand'),
                                        ),
                                        TextField(
                                          onChanged: (value) {
                                            expire = value;
                                          },
                                          decoration: const InputDecoration(labelText: 'Expire'),
                                        ),
                                        TextField(
                                          onChanged: (value) {
                                            price = value;
                                          },
                                          decoration: const InputDecoration(labelText: 'Price'),
                                        ),
                                        Text(
                                          'Date: $date',
                                          style: const TextStyle(fontSize: 12.0),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("Cancel"),
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
                                                  title: const Text("Error"),
                                                  content: const Text("Name cannot be empty."),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: const Text("OK"),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        },
                                        child: const Text("Add"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Text("    More    "),
                          ),
                        ],
                      )
                          : index == 2
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Purchase\nInvoices',
                            style: TextStyle(color: Colors.white, fontSize: 19.1),
                          ),
                          const SizedBox(height: 5.0),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text("    More    "),
                          ),
                        ],
                      )
                          : index == 3
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Patient\nProfile',
                            style: TextStyle(color: Colors.white, fontSize: 19.1),
                          ),
                          const SizedBox(height: 5.0),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text("    More    "),
                          ),
                        ],
                      )
                          : index == 4
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            '16\nExpiring',
                            style: TextStyle(color: Colors.white, fontSize: 19.1),
                          ),
                          const SizedBox(height: 5.0),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text("    More    "),
                          ),
                        ],
                      )
                          : index == 5
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            '9\nExpired',
                            style: TextStyle(color: Colors.white,fontSize: 19.1),
                          ),
                          const SizedBox(height: 5.0),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text("    More    "),
                          ),
                        ],
                      )
                          : Text(
                        gridLabels[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Container(
            height: 70,

            margin: EdgeInsets.fromLTRB(10, 0, 10, 20),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10), // Adjust the value as needed
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

      for (var doc in sellsSnapshot.docs) {
        Map<String, dynamic>? dataMap = doc.data() as Map<String, dynamic>?;

        // Get the 'data' array from the document
        List<dynamic>? dataArray = dataMap?['data'];

        // Calculate the total count of items in the 'data' array
        int count = dataArray?.length ?? 0;

        data.add(CounterData(count));
      }

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
            colorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.blue[200]!),
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
          : const Center(
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
  final String userEmail;

  const NavBar({Key? key, required this.userEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userEmail).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            var userData = snapshot.data!.data() as Map<String, dynamic>?;
            var userName = userData?['name'] ?? 'Name';
            var userEmail = userData?['email'] ?? 'Email';

            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              children: [
                DrawerHeader(
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
                        userName,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home_outlined),
                  title: Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.inventory_2_outlined),
                  title: Text('Inventory'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Inventory(userEmail: userEmail, pharmacyId: 'KYFUz7GO7IHV8tsLAYGF'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.attach_money),
                  title: Text('Sells'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Sells(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.calendar_month),
                  title: Text('Calender'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.note_alt_outlined),
                  title: Text('Notes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotesPage(),
                      ),
                    );
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Divider(),
                ListTile(
                  title: Text('LogOut'),
                  leading: Icon(Icons.exit_to_app),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          }
        },
      ),
    );
  }
}