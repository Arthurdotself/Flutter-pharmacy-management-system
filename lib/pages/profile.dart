import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:tugas1_login/backend/user_provider.dart';

import '../backend/functions.dart'; // Import your UserProvider

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _userController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  TextEditingController _searchController = TextEditingController();

  List<String> _pharmacies = [];
  List<String> _filteredPharmacies = [];
  bool _searchPharmacyMode = false; // Flag to indicate if pharmacy field is in search mode

  @override
  void initState() {
    super.initState();
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    _emailController.text = userProvider.userId;
    _bioController.text = userProvider.PharmacyId;

    _fetchUserAndName();
    _fetchPharmacies();
  }

  Future<void> _fetchUserAndName() async {
    String? userId = _emailController.text;

    if (userId != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (snapshot.exists) {
        var userData = snapshot.data() as Map<String, dynamic>?;
        var userName = userData?['name'] ?? '';
        _nameController.text = userName;
        _userController.text = userName;
      }
    }
  }

  Future<void> _fetchPharmacies() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('pharmacies').get();

    setState(() {
      _pharmacies = snapshot.docs.map((doc) => doc['name'] as String).toList();
      _filteredPharmacies = _pharmacies;
    });
  }

  void _filterPharmacies(String query) {
    setState(() {
      _filteredPharmacies = _pharmacies.where((pharmacy) => pharmacy.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslations()['edit_profile']!),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: getTranslations()['name']!),
              enabled: true,
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: getTranslations()['email']!),
                    enabled: false,
                  ),
                ),
                SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: () async {
                    User? user = FirebaseAuth.instance.currentUser;

                    if (user != null) {
                      try {
                        String? newPassword = await _showPasswordDialog();

                        if (newPassword != null) {
                          await user.updateEmail(_emailController.text);

                          UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
                          userProvider.setUserId(_emailController.text);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(getTranslations()['email_updated_successfully']!),
                            ),
                          );
                        }
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(getTranslations()['error_updating_email']!+': $error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(getTranslations()['change_email']!),
                ),
                SizedBox(width: 16.0),

              ],
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchPharmacyMode ? _searchController : _bioController,
                    decoration: InputDecoration(
                      labelText: _searchPharmacyMode ? getTranslations()['search_pharmacy']! : getTranslations()['pharmacy_name']!,
                    ),
                    enabled: _searchPharmacyMode, // Set enabled based on _searchPharmacyMode
                    onChanged: _searchPharmacyMode ? _filterPharmacies : null,
                  ),
                ),
              ],
            ), ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchPharmacyMode = true; // Activate search mode for pharmacy field
                  _searchController.clear(); // Clear search query
                });
              },
              child: Text(getTranslations()['change_pharmacy']!),
            ),
            SizedBox(height: 16.0),
            Visibility(
              visible: _searchPharmacyMode, // Set visibility based on _searchPharmacyMode
              child: Expanded(
                child: ListView.builder(
                  itemCount: _filteredPharmacies.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_filteredPharmacies[index]),
                      onTap: () {
                        _bioController.text = _filteredPharmacies[index];
                      },
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                String newName = _nameController.text;
                String newEmail = _emailController.text;
                String newUser = _userController.text;
                String newBio = _bioController.text;

                await _updateProfile(newName, newEmail, newUser, newBio);

                Navigator.pop(context);
              },
              child: Text(getTranslations()['save']!),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile(String newName, String newEmail, String newUser, String newBio) async {
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await FirebaseFirestore.instance.collection('users').doc(userProvider.userId).update({
        'name': newName,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslations()['email_updated_successfully']!),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslations()['error_updating_email']!+': $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showPasswordDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(getTranslations()['re_enter_password']!),
          content: TextField(
            obscureText: true,
            decoration: InputDecoration(labelText: getTranslations()['password']!),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(getTranslations()['cancel']!),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'password');
              },
              child: Text(getTranslations()['confirm']!),
            ),
          ],
        );
      },
    );
  }
}
