import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportIssueScreen extends StatefulWidget {
  @override
  _ReportIssueScreenState createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  TextEditingController descriptionController = TextEditingController();
  String? selectedCategory;

  final List<String> categories = [
    'Bug Report',
    'Feature Request',
    'UI/UX Issue',
    'Performance Problem',
    'Other',
  ];


  void _submitIssue() async {
    String description = descriptionController.text;

    // Check if category and description are not empty
    if (selectedCategory != null && description.isNotEmpty) {
      // Add issue to Firestore
      await FirebaseFirestore.instance.collection('issues').add({
        'category': selectedCategory,
        'description': description,
      });

      // Clear text fields after submitting
      descriptionController.clear();

      // Show a success message or navigate back to the previous screen
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Issue reported successfully!'),
      ));
    } else {
      // Show an error message if category or description is empty
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select a category and enter description.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report an Issue'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitIssue,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
