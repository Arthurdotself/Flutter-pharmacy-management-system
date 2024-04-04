import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';
import 'package:tugas1_login/pages/Inventory.dart';
import 'package:tugas1_login/pages/sells.dart';
import 'package:tugas1_login/pages/notes.dart';
import 'package:provider/provider.dart';
import 'package:tugas1_login/backend/user_provider.dart';
import 'package:tugas1_login/pages/login.dart';
import 'package:tugas1_login/main.dart';
import 'package:tugas1_login/pages/setting.dart';
import 'home.dart';
import 'notes.dart';
import 'package:tugas1_login/pages/purchaseInvoices.dart';
import 'package:tugas1_login/pages/dashboard.dart';
import 'package:tugas1_login/pages/expiring&expired.dart';
import 'package:tugas1_login/pages/tasks.dart';
import 'package:tugas1_login/pages/test.dart';


class DashboardPage extends StatefulWidget {
  final String userId;
  final String PharmacyId;

  const DashboardPage({Key? key, required this.userId, required this.PharmacyId}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
  Future<int> getSellsCount(String pharmacyId) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('pharmacies').doc(pharmacyId).collection('sells').get();

    return snapshot.docs.length;
  }
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<int> _medicinesCountFuture;
  List<CounterData> dailySales = [];

  @override
  void initState() {
    super.initState();
    _medicinesCountFuture = getMedicinesCount();
    fetchSalesData();
  }
  Future<int> countTasks(BuildContext context) async {
    try {
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      String userId = userProvider.userId;
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).collection('tasks').get();

      int totalTasks = querySnapshot.size;
      int completedTasks = querySnapshot.docs.where((doc) => doc['isCompleted'] == true).length;
      int pendingTasks = totalTasks - completedTasks;

      print('Total tasks: $totalTasks');
      print('Completed tasks: $completedTasks');
      print('Pending tasks: $pendingTasks');

      return totalTasks; // Return the total number of tasks
    } catch (error) {
      print('Error counting tasks: $error');
      return 0; // Return 0 in case of an error
    }
  }


  Future<int> getExpiringCount() async {
    // Get today's date
    DateTime now = DateTime.now();

    // Define the start and end dates for the range (e.g., 24 hours before and after today)
    DateTime startDate = DateTime(now.year, now.month, now.day - 1); // 24 hours before today
    DateTime endDate = DateTime(now.year, now.month, now.day + 1); // 24 hours after today

    // Query shipments within the date range
    QuerySnapshot shipmentsSnapshot = await FirebaseFirestore.instance
        .collection('pharmacies')
        .doc(widget.PharmacyId)
        .collection('medicines')
        .where('shipments.date', isGreaterThanOrEqualTo: startDate, isLessThan: endDate)
        .get();

    // Initialize the count of medicines
    int medicinesCount = 0;

    // Iterate over each document in the shipments collection
    for (QueryDocumentSnapshot doc in shipmentsSnapshot.docs) {
      // Get the list of shipments for the current document
      List<dynamic> shipments = doc['shipments'];

      // Iterate over each shipment in the list
      for (dynamic shipment in shipments) {
        // Extract the shipment date
        DateTime shipmentDate = DateTime.parse(shipment['date']);

        // Check if the shipment date is within the specified range
        if (shipmentDate.isAfter(startDate) && shipmentDate.isBefore(endDate)) {
          // Increment the count of medicines associated with this shipment
          medicinesCount++;
        }
      }
    }

    return medicinesCount;
  }

  Future<int> getMedicinesCount() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('pharmacies').doc(widget.PharmacyId).collection('medicines').get();

    return snapshot.docs.length;
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
      drawer: NavBar(userId: widget.userId),
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
                            UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
                            String userId = userProvider.userId;
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Inventory(userEmail: userId, pharmacyId: 'KYFUz7GO7IHV8tsLAYGF' ),
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
                    future: widget.getSellsCount(widget.PharmacyId),
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
                        number: snapshot.connectionState == ConnectionState.done ? snapshot.data ?? 0 : null,
                        color: Colors.blue.shade50,
                        iconColor: Colors.orange.shade800,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TestNewThingsPage()),
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
                    iconColor: Colors.teal.shade500,// Customize color
                    onTap: () {

                    },
                  ),
                ),
                SizedBox(width: 10.0),
                Expanded(
                  flex: 1,
                  child: FutureBuilder<int>(
                    future: countTasks(context), // Use the countTasks method to fetch the count
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else {
                        int? tasksCount = snapshot.data; // Get the tasks count from the snapshot
                        return _buildDashboardItem(
                          title: 'Tasks',
                          icon: Icons.assignment,
                          number: tasksCount, // Use the tasks count
                          color: Colors.blue.shade50,
                          iconColor: Colors.yellow.shade700, // Customize color
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TasksPage()),
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
            SizedBox(height: 10.0),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: dailySales.isNotEmpty ? _buildBarChart() : Center(child: CircularProgressIndicator()),
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
  Future<void> fetchSalesData() async {
    try {
      // Calculate the date 7 days ago
      DateTime sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));

      // Query the Firestore collection for sells data within the last 7 days
      QuerySnapshot sellsSnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(widget.PharmacyId)
          .collection('sells')
          .where('date', isGreaterThanOrEqualTo: sevenDaysAgo) // Filter data for the last 7 days
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




  Widget _buildBarChart() {
    // Convert CounterData into DaySales for charting
    List<DaySales> daySalesList = dailySales.map((data) => DaySales(data.count.toString(), data.count)).toList();

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
    home: DashboardPage(userId: 'user_id', PharmacyId: 'pharmacy_id'),
  ));
}

class NavBar extends StatelessWidget {
  final String userId;

  const NavBar({Key? key, required this.userId}) : super(key: key);

  Future<void> _uploadImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker(); // Declare _picker here

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text('Take Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _getImage(picker, ImageSource.camera);
                  },
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                ),
                GestureDetector(
                  child: Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _getImage(picker, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImagePicker picker, ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      try {
        firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('user_photos')
            .child('${userId}_avatar.jpg');

        await ref.putFile(imageFile);
        String downloadURL = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(userId).update({'photoURL': downloadURL});
      } catch (error) {
        print('Error uploading image: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
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
                        onTap: () => _uploadImage(context),
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
                        builder: (context) => DashboardPage( userId: userId, PharmacyId: 'KYFUz7GO7IHV8tsLAYGF',),
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
                        builder: (context) => Inventory(userEmail: userId, pharmacyId: 'KYFUz7GO7IHV8tsLAYGF' ),
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
                        builder: (context) => Sells(userEmail: userId, pharmacyId: 'KYFUz7GO7IHV8tsLAYGF'),
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
