import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:tugas1_login/pages/Inventory.dart';
import 'package:tugas1_login/pages/sells.dart';
import 'package:tugas1_login/pages/notes.dart';
import 'package:provider/provider.dart';
import 'package:tugas1_login/backend/user_provider.dart';
import 'package:tugas1_login/pages/login.dart';
import 'package:tugas1_login/main.dart';

import 'notes.dart';
import 'package:tugas1_login/pages/purchaseInvoices.dart';
import 'package:tugas1_login/pages/dashboard.dart';

class Dashbord extends StatefulWidget {
  final String userId;
  final String PharmacyId;

  const Dashbord({Key? key, required this.userId,required this.PharmacyId}) : super(key: key);

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
      drawer: NavBar(userId: widget.userId),
      backgroundColor: Colors.blue[50],
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 40,
                margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                child: Text(
                  "Pharmacist Dashboard",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: GridView.count(
                  shrinkWrap: true,
                  padding: charts.DatumLegend.defaultCellPadding,
                  physics: NeverScrollableScrollPhysics(),
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
                                future: FirebaseFirestore.
                                instance.collection('pharmacies').
                                doc(widget.PharmacyId).
                                collection('medicines')
                                    .get(),
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
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => Inventory(userEmail: widget.userId, pharmacyId: widget.PharmacyId),
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
                              FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('pharmacies')
                                    .doc(widget.PharmacyId)
                                    .collection('sells')
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Text("Loading...");
                                  } else if (snapshot.hasError) {
                                    return Text("Error: ${snapshot.error}");
                                  } else {
                                    var sellsData = snapshot.data!.docs.length; // Cast to Map<String, dynamic> or null

                                    if (sellsData != null ) {
                                    //  var dataCount = (sellsData['data'] as List).length;

                                      return Column(
                                        children: [
                                          Text(
                                            "$sellsData\nSells",
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
                                                CollectionReference sellsCollection = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('sells');
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
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => PurchaseInvoices()),
                                  );
                                },

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
                                style: TextStyle(color: Colors.white, fontSize: 19.1),
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
              Flexible(
                child: YourBarChart(userId: widget.userId , PharmacyId:widget.PharmacyId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YourBarChart extends StatefulWidget {
  final String userId;
  final String PharmacyId;

  const YourBarChart({Key? key, required this.userId,required this.PharmacyId}) : super(key: key);

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
      QuerySnapshot sellsSnapshot = await FirebaseFirestore.instance.
      collection('pharmacies').
      doc(widget.PharmacyId).
      collection('sells')
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
                        builder: (context) => DashboardPage(),
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
                        builder: (context) => Inventory(userEmail: userId, pharmacyId: 'KYFUz7GO7IHV8tsLAYGF'),
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
