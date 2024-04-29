import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PharmacyManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacy Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PharmacyManagerPage(),
    );
  }
}

class PharmacyManagerPage extends StatefulWidget {
  @override
  _PharmacyManagerPageState createState() => _PharmacyManagerPageState();
}

class _PharmacyManagerPageState extends State<PharmacyManagerPage>
    with SingleTickerProviderStateMixin {
  // Firestore instance
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // List to store tasks
  List<String> tasks = [];

  // List to store employees
  List<String> employees = [];

  // List to store pending employee requests
  List<String> pendingRequests = [];

  // TextEditingController for new task input
  TextEditingController _taskController = TextEditingController();

  // TextEditingController for new employee input
  TextEditingController _employeeController = TextEditingController();

  // TextEditingController for new employee request input
  TextEditingController _employeeRequestController = TextEditingController();

  // TabController for managing tabs
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize TabController with three tabs
    _tabController = TabController(length: 3, vsync: this);
    // Load initial data
    _loadData();
  }

  // Load initial data from Firestore
  Future<void> _loadData() async {
    // Load tasks
    QuerySnapshot taskSnapshot = await firestore.collection('tasks').get();
    setState(() {
      tasks = taskSnapshot.docs.map((doc) => doc['taskName'] as String).toList();
    });

    // Load employees
    QuerySnapshot employeeSnapshot = await firestore.collection('employees').get();
    setState(() {
      employees = employeeSnapshot.docs.map((doc) => doc['employeeName'] as String).toList();
    });

    // Load pending employee requests
    QuerySnapshot requestSnapshot = await firestore.collection('users').where('approved', isEqualTo: false).get();
    setState(() {
      pendingRequests = requestSnapshot.docs.map((doc) => doc['employeeName'] as String).toList();
    });
  }

  @override
  void dispose() {
    // Dispose controllers and tab controller
    _taskController.dispose();
    _employeeController.dispose();
    _employeeRequestController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pharmacy Manager'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tasks'),
            Tab(text: 'Employees'),
            Tab(text: 'Pending Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tasks Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _taskController,
                        decoration: InputDecoration(
                          labelText: 'Add Task',
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _addTask();
                      },
                      child: Text('Add'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(tasks[index]),
                    );
                  },
                ),
              ),
            ],
          ),
          // Employees Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _employeeController,
                        decoration: InputDecoration(
                          labelText: 'Add Employee',
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _addEmployee();
                      },
                      child: Text('Add'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(employees[index]),
                    );
                  },
                ),
              ),
            ],
          ),
          // Pending Requests Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _employeeRequestController,
                        decoration: InputDecoration(
                          labelText: 'Add Employee Request',
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _addEmployeeRequest();
                      },
                      child: Text('Add'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: pendingRequests.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(pendingRequests[index]),
                      trailing: IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () {
                          _acceptPendingUser(pendingRequests[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Function to add a new task
  void _addTask() async {
    await firestore.collection('tasks').add({
      'taskName': _taskController.text,
    });
    _taskController.clear();
    _loadData(); // Reload data after adding a task
  }

  // Function to add a new employee
  void _addEmployee() async {
    await firestore.collection('employees').add({
      'employeeName': _employeeController.text,
    });
    _employeeController.clear();
    _loadData(); // Reload data after adding an employee
  }

  // Function to add a new employee request
  void _addEmployeeRequest() async {
    await firestore.collection('users').add({
      'employeeName': _employeeRequestController.text,
      'approved': false,
    });
    _employeeRequestController.clear();
    _loadData(); // Reload data after adding a request
  }

  // Function to accept a pending user
  void _acceptPendingUser(String employeeName) async {
    QuerySnapshot userSnapshot = await firestore.collection('users').where('employeeName', isEqualTo: employeeName).get();
    if (userSnapshot.docs.isNotEmpty) {
      await userSnapshot.docs.first.reference.update({
        'approved': true,
      });
      _loadData(); // Reload data after accepting the user
    } else {
      print('User document not found');
    }
  }
}
