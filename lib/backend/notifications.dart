import 'package:flutter/material.dart'; // Import Flutter material library

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:tugas1_login/backend/user_provider.dart';

import '../main.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Trigger fetchExpiredMedicines after 10 seconds
    Future.delayed(Duration(seconds: 10), () {
      NotificationHandler.fetchExpiredMedicines(context); // Pass the context here
    });

    return MaterialApp(
      title: 'My App',
      home: Scaffold(
        appBar: AppBar(
          title: Text('My App'),
        ),
        body: Center(
          child: Text('Hello World'),
        ),
      ),
    );
  }
}


  // Trigger fetchExpiredMedicines after 10 seconds
  Future.delayed(Duration(seconds: 10), () {
    NotificationHandler.fetchExpiredMedicines();
  });
}

class NotificationHandler {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> fetchExpiredMedicines(BuildContext context) async { // Pass BuildContext as a parameter
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    String pharmacyId = userProvider.PharmacyId;
    try {
      // Query the Firestore collection for expired medicines
      QuerySnapshot expiredMedicinesSnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('medicines')
          .where('shipments', isLessThanOrEqualTo: [
        {'expire': Timestamp.now()} // This ensures that at least one shipment has an expire field greater than or equal to the current time
      ])
          .get();

      // Convert the retrieved documents into a list of maps
      List<Map<String, dynamic>> expiredMedicines = expiredMedicinesSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Send notifications for expired medicines
      for (var medicine in expiredMedicines) {
        // Check if the medicine has expired
        DateTime expireDate = (medicine['shipments'] as List<dynamic>)[0]['expire'].toDate();
        DateTime now = DateTime.now();
        Duration timeDifference = expireDate.difference(now);

        if (timeDifference.inDays < 0) {
          // The medicine has expired, send a notification
          await _showNotification(
            title: 'Medicine Expired',
            body: 'The medicine ${medicine['name']} has expired.',
          );
        } else if (timeDifference.inDays <= 30 && timeDifference.inDays >= 0) {
          // The medicine is expiring within 30 days, send a notification
          await _showNotification(
            title: 'Medicine Expiring Soon',
            body: 'The medicine ${medicine['name']} is expiring in ${timeDifference.inDays} days.',
          );
        }
      }
    } catch (error) {
      print('Error fetching expired medicines: $error');
    }
  }

  static Future<void> _showNotification({required String title, required String body}) async {
    // Create a notification details object
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'expired_medicines_channel', // Channel ID
      'Expired Medicines', // Channel name
      'Notifications for expired medicines', // Channel description
      importance: Importance.max,
      priority: Priority.high,
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Show the notification
    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title, // Notification title
      body, // Notification body
      platformChannelSpecifics,
      payload: 'expired_medicines', // Payload for onTap event
    );
  }
}
