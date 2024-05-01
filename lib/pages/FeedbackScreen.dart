import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tugas1_login/backend/functions.dart';

class FeedbackScreen extends StatelessWidget {
  final TextEditingController feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Provide Feedback'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your Feedback',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: feedbackController,
              decoration: InputDecoration(
                hintText: 'Enter your feedback here',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _submitFeedback(context);
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback(BuildContext context) async {
    String feedback = feedbackController.text;
    await FirebaseFirestore.instance.collection('feedback').add({
      'user': userEmail,
      'description': feedback,
    });
    print('Feedback: $feedback');
    // Optionally, you can show a confirmation message or navigate to another screen
    Navigator.pop(context); // Navigate back to the previous screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank you for your feedback!'),
      ),
    );
  }
}
