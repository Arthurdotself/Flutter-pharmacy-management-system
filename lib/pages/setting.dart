import 'package:flutter/material.dart';
import 'package:tugas1_login/pages/profile.dart';

class LanguageSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Language'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('English'),
            onTap: () {
              // Set selected language to English
              // You can implement language selection logic here
              Navigator.pop(context); // Close language selection page
            },
          ),
          ListTile(
            title: Text('Spanish'),
            onTap: () {
              // Set selected language to Spanish
              // You can implement language selection logic here
              Navigator.pop(context); // Close language selection page
            },
          ),
          ListTile(
            title: Text('Kurdish'),
            onTap: () {
              // Set selected language to Spanish
              // You can implement language selection logic here
              Navigator.pop(context); // Close language selection page
            },
          ),
          ListTile(
            title: Text('Japanese'),
            onTap: () {
              // Set selected language to Spanish
              // You can implement language selection logic here
              Navigator.pop(context); // Close language selection page
            },
          ),
          // Add more languages as needed
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildHeader('Account'),
          _buildListItem(Icons.person, 'Edit Profile', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditProfilePage()),
            );
          }),

          _buildListItem(Icons.lock, 'Change Password', () {
            // Navigate to change password page
          }),
          _buildDivider(),
          _buildHeader('Notifications'),
          _buildSwitchListItem('Receive Notifications', true, (bool value) {
            // Handle switch value change
          }),
          _buildDivider(),
          _buildHeader('App Settings'),
          _buildListItem(Icons.language, 'Language', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LanguageSelectionPage()), // Navigate to LanguageSelectionPage
            );
          }),
          _buildDivider(),
          _buildHeader('Support'),
          _buildListItem(Icons.help, 'Help & Feedback', () {
            // Navigate to help and feedback page
          }),
          _buildDivider(),
          _buildListItem(Icons.info, 'About', () {
            // Navigate to about page
          }),
          _buildDivider(),
          _buildListItem(Icons.exit_to_app, 'Log Out', () {
            // Implement log out functionality
          }, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildListItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchListItem(String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      thickness: 1,
      height: 1,
    );
  }
}
