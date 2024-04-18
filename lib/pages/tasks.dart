import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../backend/functions.dart';
import '../backend/user_provider.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_tabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _tabChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Unfinished Tasks'),
            Tab(text: 'Completed Tasks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UnfinishedTasksPage(),
          CompletedTasksPage(),
        ],
      ),
    );
  }
}

class UnfinishedTasksPage extends StatelessWidget {
  const UnfinishedTasksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder(
              stream: getTasksStream(context),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  List<Widget> taskItems = snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TaskItem(
                        task: Task(
                          documentId: doc.id,
                          isCompleted: data['isCompleted'],
                          title: data['title'],
                          description: data['description'],
                        ),
                      ),
                    );
                  }).toList();

                  return Column(
                    children: taskItems,
                  );
                }
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                createTaskDocument(context);
              },
              child: const Text('Create New Task'),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> createTaskDocument(BuildContext context) async {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
                  String userId = userProvider.userId;
                  CollectionReference tasksCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection('tasks');
                  await tasksCollection.add({
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'isCompleted': false,
                    'created_at': DateTime.now(),
                  });
                  if (kDebugMode) {
                    print('Task document added successfully');
                  }
                  Navigator.of(context).pop();
                } catch (error) {
                  if (kDebugMode) {
                    print('Error adding task document: $error');
                  }
                }
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

class CompletedTasksPage extends StatelessWidget {
  const CompletedTasksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder(
              stream: getCompletedTasksStream(context),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  List<Widget> taskItems = snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TaskItem(
                        task: Task(
                          documentId: doc.id,
                          isCompleted: data['isCompleted'],
                          title: data['title'],
                          description: data['description'],
                        ),
                      ),
                    );
                  }).toList();

                  return Column(
                    children: taskItems,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TaskItem extends StatelessWidget {
  final Task task;

  const TaskItem({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showDescription(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                task.title, // Show title instead of description
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: task.isCompleted ? Colors.green : Colors.black,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                task.isCompleted ? Icons.check_circle : Icons.circle,
                color: task.isCompleted ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                toggleTaskCompletion(context, task);
              },
            ),
          ],
        ),
      ),
    );
  }


  void _showDescription(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(task.title),
          content: Text(task.description),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
