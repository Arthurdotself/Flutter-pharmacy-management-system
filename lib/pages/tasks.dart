import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StreamBuilder(
            stream: _getTasksStream(context),
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
                        description: data['description'],
                        isCompleted: data['isCompleted'],
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
    );
  }

  Stream<QuerySnapshot> _getTasksStream(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    String userId = userProvider.userId;
    return FirebaseFirestore.instance.collection('users').doc(userId).collection('tasks').where('isCompleted', isEqualTo: false).snapshots();
  }

  Future<void> createTaskDocument(BuildContext context) async {
    try {
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      String userId = userProvider.userId;
      CollectionReference tasksCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection('tasks');
      await tasksCollection.add({
        'description': 'New Task',
        'isCompleted': false,
        'created_at': DateTime.now(),
      });
      if (kDebugMode) {
        print('Task document added successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error adding task document: $error');
      }
    }
  }
}

class CompletedTasksPage extends StatelessWidget {
  const CompletedTasksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Completed Tasks Page'),
    );
  }
}

class Task {
  final String documentId; // Add this property to store the document ID
  final String description;
  final bool isCompleted;

  Task({
    required this.documentId,
    required this.description,
    required this.isCompleted,
  });
}

class TaskItem extends StatelessWidget {
  final Task task;

  const TaskItem({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
              task.description,
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
              toggleTaskCompletion(context, task); // Call function to toggle task completion
            },
          ),
        ],
      ),
    );
  }

  void toggleTaskCompletion(BuildContext context, Task task) async {
    try {
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      String userId = userProvider.userId;
      CollectionReference tasksCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection('tasks');

      // Update the task document in Firestore
      await tasksCollection.doc(task.documentId).update({
        'isCompleted': !task.isCompleted,
      });

      if (kDebugMode) {
        print('Task completion status updated successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error updating task completion status: $error');
      }
    }
  }
}