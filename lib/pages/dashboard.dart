import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tugas1_login/pages/Inventory.dart';
import 'package:tugas1_login/pages/sells.dart';
import 'package:tugas1_login/pages/notes.dart';
import 'package:provider/provider.dart';
import 'package:tugas1_login/backend/user_provider.dart';
import 'package:tugas1_login/main.dart';
import 'package:tugas1_login/pages/setting.dart';
import 'package:tugas1_login/pages/tasks.dart';
import 'package:tugas1_login/pages/test.dart';
import 'package:tugas1_login/pages/patientProfile.dart';
import '../backend/functions.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {

  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<int> _medicinesCountFuture;
  List<CounterData> dailySales = [];

  @override
  void initState() {
    setUserEmail(context);
    super.initState();
    _medicinesCountFuture = getMedicinesCount();
    fetchSellsData(selectedDate: '7').then((data) {
      setState(() {
        dailySales = data.cast<CounterData>();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 20.0, // Adjust font size as needed
            fontWeight: FontWeight.bold, // Adjust font weight as needed
            color: Colors.black, // Adjust text color as needed
          ),
        ),
      ),
      drawer: NavBar(),
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // First section
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<int>(
                    future: _medicinesCountFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else {
                        int? medicinesCount = snapshot.data;
                        return _buildDashboardItem(
                          title: 'Medicines\n',
                          icon: Icons.local_pharmacy,
                          number: medicinesCount,
                          color: Colors.blue.shade50,
                          iconColor: Colors.blue.shade800,
                          onTap: () {
                            UserProvider userProvider = Provider.of<
                                UserProvider>(context, listen: false);
                            String userId = userProvider.userId;
                            String pharmacyId = userProvider.PharmacyId;
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Inventory(userEmail: userId,
                                        pharmacyId: pharmacyId),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                SizedBox(width: 10.0),
                Expanded(
                  child: FutureBuilder<int>(
                    future: getSellsCount(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else {
                        int? sellsCount = snapshot.data;
                        return _buildDashboardItem(
                          title: 'Add\nSells',
                          icon: Icons.monetization_on,
                          number: sellsCount,
                          color: Colors.blue.shade50,
                          iconColor: Colors.green.shade700,
                          onTap: () {
                            sellscanBarcode(context);
                            // Add functionality for the Sells container
                          },
                        );
                      }
                    },
                  ),
                ),

                SizedBox(width: 10.0),
                Expanded(
                  child: FutureBuilder<int>(
                    future: getExpiringCount(),
                    builder: (context, snapshot) {
                      return _buildDashboardItem(
                        title: 'Expiring & Expired',
                        icon: Icons.timer,
                        // number: snapshot.connectionState == ConnectionState.done ? snapshot.data ?? 0 : null,
                        color: Colors.blue.shade50,
                        iconColor: Colors.orange.shade800,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TestNewThingsPage()),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.0),

            // Second section
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildDashboardItem(
                    title: 'Patient Profile',
                    icon: Icons.account_circle,
                    color: Colors.blue.shade50,
                    iconColor: Colors.teal.shade500,
                    // Customize color
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PatientProfilePage()),
                      );
                    },
                  ),
                ),
                SizedBox(width: 10.0),
                Expanded(
                  flex: 1,
                  child: FutureBuilder<int>(
                    future: countTasks(context),
                    // Use the countTasks method to fetch the count
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else {
                        int? tasksCount = snapshot
                            .data; // Get the tasks count from the snapshot
                        return _buildDashboardItem(
                          title: 'Tasks',
                          icon: Icons.assignment,
                          number: tasksCount,
                          // Use the tasks count
                          color: Colors.blue.shade50,
                          iconColor: Colors.yellow.shade700,
                          // Customize color
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => TasksPage()),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.0),

            // Third section (Bar chart)
            Text(
              'Sells of Last 7 Days',
              style: TextStyle(
                fontSize: 20.0, // Adjust font size as needed
                fontWeight: FontWeight.bold, // Adjust font weight as needed
                color: Colors.black, // Adjust text color as needed
              ),
            ),
            SizedBox(height: 10.0), Expanded(
              child: Container(
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: dailySales.isNotEmpty ? _buildBarChart(
                    dailySales.cast<Map<String, dynamic>>()) : Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem({
    required String title,
    required IconData icon,
    int? number,
    required Color color, // Color for the container background
    required Color iconColor, // Color for the icon
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: color, // Set container color
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50.0,
              color: iconColor, // Set icon color
            ),
            SizedBox(height: 10.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.0, // Adjust font size as needed
                color: Colors.black, // Adjust text color as needed
              ),
            ),
            SizedBox(height: 5.0),
            Text(
              number != null ? '$number' : '',
              style: TextStyle(
                fontSize: 16.0, // Adjust font size as needed
                color: Colors.black, // Adjust text color as needed
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Future<void> fetchSellsData() async {
  //   try {
  //     // Calculate the date 7 days ago
  //     DateTime sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
  //
  //     // Query the Firestore collection for sells data within the last 7 days
  //     QuerySnapshot sellsSnapshot = await FirebaseFirestore.instance
  //         .collection('pharmacies')
  //         .doc(widget.PharmacyId)
  //         .collection('sells')
  //         .where('date', isGreaterThanOrEqualTo: sevenDaysAgo) // Filter data for the last 7 days
  //         .get();
  //
  //     List<CounterData> data = [];
  //
  //     for (var doc in sellsSnapshot.docs) {
  //       Map<String, dynamic>? dataMap = doc.data() as Map<String, dynamic>?;
  //
  //       // Get the 'data' array from the document
  //       List<dynamic>? dataArray = dataMap?['data'];
  //
  //       // Calculate the total count of items in the 'data' array
  //       int count = dataArray?.length ?? 0;
  //
  //       data.add(CounterData(count));
  //     }
  //
  //     setState(() {
  //       dailySales = data;
  //     });
  //   } catch (error) {
  //     print("Error fetching sales data: $error");
  //   }
  // }


  Widget _buildBarChart(List<Map<String, dynamic>> firebaseData) {
    // Convert Firebase data into a map of time and item counts
    Map<String, int> itemCountByTime = {};

    firebaseData.forEach((data) {
      // Extract the timestamp and convert it to a date string
      String time = DateFormat('EEE').format(data['time'].toDate());

      // Print the timestamp and date string for debugging
      print('Timestamp: ${data['time']}, Date: $time');

      // Update the map with the count for the corresponding date
      itemCountByTime.update(
        time,
            (value) => value + 1,
        ifAbsent: () => 1,
      );
    });
    // Convert the map into a list of DaySales
    List<DaySales> daySalesList = itemCountByTime.entries
        .map((entry) => DaySales(entry.key, entry.value))
        .toList();

    // Define the series list using the converted data
    List<charts.Series<DaySales, String>> seriesList = [
      charts.Series(
        id: 'Sales',
        data: daySalesList,
        domainFn: (DaySales sales, _) => sales.day,
        measureFn: (DaySales sales, _) => sales.amount,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      )
    ];

    // Return the BarChart widget with the series list
    return charts.BarChart(
      seriesList,
      animate: true,
      barGroupingType: charts.BarGroupingType.grouped,
    );
  }
}

  class DaySales {
  final String day;
  final int amount;

  DaySales(this.day, this.amount);
}


void main() {
  runApp(MaterialApp(
    home: DashboardPage(),
  ));
}

class NavBar extends StatelessWidget {

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
                      GestureDetector(
                        onTap: () => uploadImage(context),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(
                            userData?['photoURL'] ?? 'https://firebasestorage.googleapis.com/v0/b/pharmacy-management-syst-cdbf2.appspot.com/o/2df47b6e-2d22-419e-979c-a2899a5be168.jpeg?alt=media&token=283932e4-414c-44c2-820f-2204fb12b41e',
                          ),
                          radius: 40,
                        ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DashboardPage( ),
                      ),
                    );
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
                        builder: (context) => Inventory(userEmail: userEmail, pharmacyId: pharmacyId ),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: Icon(Icons.attach_money_outlined),
                  title: Text('Sells'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Sells(userEmail: userEmail, pharmacyId: pharmacyId),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.note_outlined),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(),
                      ),
                    );
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  onTap: () {
                    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
                    userProvider.setUserId('');
                    //context.read<UserProvider>().signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyApp(),
                      ),
                    );
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
