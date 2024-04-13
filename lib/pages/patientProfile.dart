import 'package:flutter/material.dart';

class PatientProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Profile'),
      ),
      body: Stack(
        children: [
          // Your main content goes here
          Container(
            color: Colors.white, // Change the color as needed
            // Add your main content widgets here
          ),
          // Overlay for "Under Construction" text
          Positioned.fill(
            child: Center(
              child: Transform.rotate(
                angle: 45 * 3.1415926535897932 / 180,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.white,
                  child: Text(
                    'Under Construction ⚠️',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
