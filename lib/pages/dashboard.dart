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
import 'package:tugas1_login/pages/ExpiringExpired.dart';
import 'package:tugas1_login/pages/patientProfile.dart';
import '../backend/functions.dart';
import 'package:intl/intl.dart';
import 'package:tugas1_login/pages/managePharmacy.dart';

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
          (getTranslations()['dashboard']!),
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container( // Container 1
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: 190,
                    child: _buildDashboardItem(
                      title: (getTranslations()['medicines']!),
                      icon: Icons.local_pharmacy,
                      future: _medicinesCountFuture,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Inventory(),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Container( // Container 2
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: 190, // Specify the height as needed
                    child: _buildDashboardItem(
                      title: (getTranslations()['add_sells']!),
                      icon: Icons.monetization_on,
                      future: getSellsCount(),
                      onTap: () {
                        sellscanBarcode(context);
                      },
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Container( // Container 3
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: 190,
                    child: _buildDashboardItem(
                      title: (getTranslations()['expiring_expired']!),
                      icon: Icons.timer,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExpiringExpiredPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),


            SizedBox(height: 15.0),
            // Second section
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4619,
                    height: 170,
                    child: Expanded(
                      child: _buildDashboardItem(
                        title: (getTranslations()['patient_profile']!),
                        icon: Icons.account_circle,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientProfilePage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 10.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4619,
                    height: 170,
                    child: Expanded(
                      child: _buildDashboardItem(
                        title: (getTranslations()['tasks']!),
                        icon: Icons.assignment,
                        future: countTasks(context),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TasksPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.0),
            // Third section (Bar chart)
            Text(
              (getTranslations()['sells_of_last_7_days']!),
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10.0),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: dailySales.isNotEmpty
                    ? _buildBarChart(dailySales.cast<Map<String, dynamic>>())
                    : Center(
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
    Future<int>? future,
    required VoidCallback onTap,
    Color iconColor = Colors.blue,
  }) {
    return AnimatedDashboardItem(
      title: title,
      icon: icon,
      future: future,
      onTap: onTap,
      iconColor: iconColor,
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> firebaseData) {
    Map<String, int> itemCountByTime = {};

    firebaseData.forEach((data) {
      String time = DateFormat('EEE').format(data['time'].toDate());

      itemCountByTime.update(
        time,
            (value) => value + 1,
        ifAbsent: () => 1,
      );
    });

    List<DaySales> daySalesList = itemCountByTime.entries
        .map((entry) => DaySales(entry.key, entry.value))
        .toList();

    List<charts.Series<DaySales, String>> seriesList = [
      charts.Series(
        id: 'Sales',
        data: daySalesList,
        domainFn: (DaySales sales, _) => sales.day,
        measureFn: (DaySales sales, _) => sales.amount,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      )
    ];

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

class AnimatedDashboardItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final Future<int>? future;
  final VoidCallback onTap;
  final Color iconColor;

  const AnimatedDashboardItem({
    Key? key,
    required this.title,
    required this.icon,
    this.future,
    required this.onTap,
    this.iconColor = Colors.blue,
  }) : super(key: key);

  @override
  _AnimatedDashboardItemState createState() => _AnimatedDashboardItemState();
}

class _AnimatedDashboardItemState extends State<AnimatedDashboardItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0.0, 50.0 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 50.0,
                color: widget.iconColor,
              ),
              SizedBox(height: 10.0),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 5.0),
              if (widget.future != null)
                FutureBuilder<int>(
                  future: widget.future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasData) {
                      return Text(
                        '${snapshot.data}',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black,
                        ),
                      );
                    } else {
                      return SizedBox();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
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
            var userEmail = userData?['email'] ?? 'Email';
            return FutureBuilder<bool>(
              future: checkOwnership(userEmail),
              builder: (context, ownershipSnapshot) {
                if (ownershipSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (ownershipSnapshot.hasError || !ownershipSnapshot.data!) {
                  // If ownership check fails or user is not the owner, hide the "Manager" item
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
                              userData?['name'] ?? 'Name',
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
                        title: Text(getTranslations()['home']!),
                        onTap: () {
                          Navigator.pop(context);

                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.inventory_2_outlined),
                        title: Text(getTranslations()['inventory']!),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Inventory(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.attach_money_outlined),
                        title: Text(getTranslations()['sells']!),
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
                        title: Text(getTranslations()['notes']!),
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
                        title: Text(getTranslations()['settings']!),
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
                        title: Text(getTranslations()['logout']!),
                        onTap: () {
                          UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
                          userProvider.setUserId('');
                          userProvider.setPharmacyId('');
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
                } else {
                  // If user is the owner, display drawer with user's information and navigation items including the "Manager" item
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
                              userData?['name'] ?? 'Name',
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
                        title: Text(getTranslations()['home']!),
                        onTap: () {
                          Navigator.pop(context);

                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.inventory_2_outlined),
                        title: Text(getTranslations()['inventory']!),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Inventory(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.attach_money_outlined),
                        title: Text(getTranslations()['sells']!),
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
                        title: Text(getTranslations()['notes']!),
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
                        leading: Icon(Icons.manage_accounts),
                        title: Text('Manager'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PharmacyManagerApp(),
                            ),
                          );
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.settings),
                        title: Text(getTranslations()['settings']!),
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
                        title: Text(getTranslations()['logout']!),
                        onTap: () {
                          UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
                          userProvider.setUserId('');
                          userProvider.setPharmacyId('');
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
            );
          }
        },
      ),
    );
  }
}
