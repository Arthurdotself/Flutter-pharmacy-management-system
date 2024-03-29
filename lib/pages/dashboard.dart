import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class DashboardPage extends StatelessWidget {
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
      drawer: const NavBar(),
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // First section
            Row(
              children: [
                Expanded(
                  child: _buildDashboardItem(
                    title: 'Medicines\n',
                    icon: Icons.local_pharmacy,
                    number: 50, // Replace with actual number of medicines
                    color: Colors.blue.shade50,
                    iconColor: Colors.blue.shade800,// Customize color
                    onTap: () {
                      // Add functionality for the Medicines container
                    },
                  ),
                ),
                SizedBox(width: 10.0),
                Expanded(
                  child: _buildDashboardItem(
                    title: 'Add\nSells',
                    icon: Icons.monetization_on,
                    number: 100, // Replace with actual number of sells
                    color: Colors.blue.shade50,
                    iconColor: Colors.green.shade700,// Customize color
                    onTap: () {
                      // Add functionality for the Sells container
                    },
                  ),
                ),
                SizedBox(width: 10.0),
                Expanded(
                  child: _buildDashboardItem(
                    title: 'Expiring & Expired',
                    icon: Icons.timer,
                    number: 20, // Replace with actual number of expiring/expired
                    color: Colors.blue.shade50,
                    iconColor: Colors.orange.shade800,// Customize color
                    onTap: () {
                      // Add functionality for the Expiring & Expired container
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
                      // Add functionality for the Patient Profile container
                    },
                  ),
                ),
                SizedBox(width: 10.0),
                Expanded(
                  flex: 1,
                  child: _buildDashboardItem(
                    title: 'Tasks',
                    icon: Icons.assignment,
                    number: 5, // Replace with actual number of tasks
                    color: Colors.blue.shade50,
                    iconColor: Colors.yellow.shade700, // Customize color
                    onTap: () {
                      // Add functionality for the Tasks container
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: _buildBarChart(),
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


  Widget _buildBarChart() {
    // Replace this data with your actual sells data
    List<charts.Series<DaySales, String>> seriesList = [
      charts.Series(
        id: 'Sales',
        data: [
          DaySales('Day 1', 100),
          DaySales('Day 2', 150),
          DaySales('Day 3', 200),
          DaySales('Day 4', 170),
          DaySales('Day 5', 220),
          DaySales('Day 6', 190),
          DaySales('Day 7', 250),
        ],
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

void main() {
  runApp(MaterialApp(
    home: DashboardPage(),
    // theme: ThemeData(
    //   scaffoldBackgroundColor: Colors.black, // Change background color here
    // ),
  ));
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
                    fontSize: 16.0, // Adjust font size as needed
                    color: Colors.black54, // Adjust text color as needed
                  ),
                ),
                Text(
                  'belal@gmail.com',
                  style: TextStyle(
                    fontSize: 12.0, // Adjust font size as needed
                    color: Colors.black54, // Adjust text color as needed
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 16.0, // Adjust font size as needed
                color: Colors.black, // Adjust text color as needed
              ),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text(
              'Inventory',
              style: TextStyle(
                fontSize: 16.0, // Adjust font size as needed
                color: Colors.black, // Adjust text color as needed
              ),
            ),
            onTap: () {
              // Navigator.pop(context);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const Inventory(),
              //   ),
              // );
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text(
              'Sells',
              style: TextStyle(
                fontSize: 16.0, // Adjust font size as needed
                color: Colors.black, // Adjust text color as needed
              ),
            ),
            onTap: () {
              // Navigator.pop(context);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const Sells(),
              //   ),
              // );
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text(
              'Purchase Invoices',
              style: TextStyle(
                fontSize: 16.0, // Adjust font size as needed
                color: Colors.black, // Adjust text color as needed
              ),
            ),
            onTap: () {
              // Navigator.pop(context);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const Calender(),
              //   ),
              // );
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_alt_outlined),
            title: const Text(
              'Notes',
              style: TextStyle(
                fontSize: 16.0, // Adjust font size as needed
                color: Colors.black, // Adjust text color as needed
              ),
            ),
            onTap: () {
              // Navigator.pop(context);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const Notes(),
              //   ),
              // );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text(
              'Settings',
              style: TextStyle(
                fontSize: 16.0, // Adjust font size as needed
                color: Colors.black, // Adjust text color as needed
              ),
            ),
            onTap: () {
              // Navigator.pop(context);
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
            title: const Text(
              'LogOut',
              style: TextStyle(
                fontSize: 16.0, // Adjust font size as needed
                color: Colors.black, // Adjust text color as needed
              ),
            ),
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
