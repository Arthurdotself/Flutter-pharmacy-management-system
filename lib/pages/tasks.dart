import 'package:flutter/material.dart';

class TasksPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TaskItem(
              task: Task(
                description: 'Task 1: Complete project proposal',
                isCompleted: false,
              ),
            ),
            SizedBox(height: 16.0),
            TaskItem(
              task: Task(
                description: 'Task 2: Review design mockups',
                isCompleted: true,
              ),
            ),
            SizedBox(height: 16.0),
            TaskItem(
              task: Task(
                description: 'Task 3: Implement login screen',
                isCompleted: false,
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Add functionality to create new tasks
              },
              child: Text('Create New Task'),
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  final String description;
  final bool isCompleted;

  Task({
    required this.description,
    required this.isCompleted,
  });
}

class TaskItem extends StatelessWidget {
  final Task task;

  TaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
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
              // Add functionality to toggle task completion
            },
          ),
        ],
      ),
    );
  }
}
