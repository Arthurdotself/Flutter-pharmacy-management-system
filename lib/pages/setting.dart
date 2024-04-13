import 'package:flutter/material.dart';
import 'package:tugas1_login/pages/profile.dart';
import 'package:url_launcher/url_launcher.dart';


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
            title: Text('Kurdish'),
            subtitle: Text(
              'Under Construction',
              style: TextStyle(
                color: Colors.red, // Or any other color you prefer
              ),
            ),
            onTap: () {
              // Set selected language to Spanish
              // You can implement language selection logic here
              //Navigator.pop(context); // Close language selection page
            },
          ),
          ListTile(
            title: Text('Arabic'),
            subtitle: Text(
              'Under Construction',
              style: TextStyle(
                color: Colors.red, // Or any other color you prefer
              ),
            ),
            onTap: () {
              // Set selected language to Spanish
              // You can implement language selection logic here
              //Navigator.pop(context); // Close language selection page
            },
          ),
          // Add more languages as needed
        ],
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Password',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter your current password',
              ),
            ),
            SizedBox(height: 16),
            Text(
              'New Password',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter your new password',
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Confirm New Password',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirm your new password',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _handleChangePassword();
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleChangePassword() {
    String currentPassword = _currentPasswordController.text;
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    // Validate password fields
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    // Check if new password matches the confirm password
    if (newPassword != confirmPassword) {
      _showSnackBar('New password and confirm password do not match');
      return;
    }

    // Implement your logic for changing the password here

    // Clear text fields after successful password change
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    _showSnackBar('Password changed successfully');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChangePasswordPage()),
            );
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
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Help & Feedback'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Icon(Icons.contact_support),
                        title: Text('Contact Support'),
                        onTap: () {
                          _contactSupport(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.bug_report),
                        title: Text('Report an Issue'),
                        onTap: () {
                          // Implement report issue functionality
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.feedback),
                        title: Text('Provide Feedback'),
                        onTap: () {
                          // Implement feedback functionality
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          _buildListItem(Icons.info, 'About', () {
            showAboutDialog(
              context: context,
              applicationName: 'PharmAssist',
              applicationVersion: '1.0.0', // Your app version
              applicationLegalese: '© 2024 Cihan University\n', // Your company name or legal information
              children: [
                // Additional information about your app
                Text('Introducing our cutting-edge Pharmacy Management System, the ultimate solution for pharmacists and pharmacy owners to streamline their operations and enhance efficiency. Our app revolutionizes the way pharmacies manage inventory, sales, and daily tasks, making every aspect of pharmacy management a breeze.'

            'Effortlessly track and manage your inventory with real-time updates on stock levels, ensuring you never run out of essential medications or supplies. With intuitive inventory management features, you can easily organize products, track batch numbers, and monitor stock movement to optimize inventory levels and minimize waste.'

              'Say goodbye to expired medications and wasted resources with our innovative expiry date tracking feature. Our app automatically alerts you when products are nearing their expiration date, allowing you to take proactive measures to prevent losses and maintain product quality.'

            'Boost productivity and streamline workflows with our task management tools, designed to keep your pharmacy operations running smoothly. Assign tasks, set reminders, and track progress in real-time to ensure all essential activities are completed on time and with precision.'

            'Experience the future of pharmacy management with our comprehensive app, empowering pharmacists to focus on delivering exceptional patient care while our technology handles the rest. Join the countless pharmacies worldwide already benefiting from our advanced features and take your pharmacy to new heights of success today.'),
              ],
            );
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

void _contactSupport(BuildContext context) {
  // Replace 'supportEmailAddress' with your support email address
  final supportEmailAddress = 'support@example.com';

  // Replace 'subject' with a suitable subject line for the email
  final subject = 'PharmAssist Support Request';

  // You can also include additional details in the body of the email
  final body = 'Please describe your issue or question here.';

  // Construct the email Uri
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: supportEmailAddress,
    queryParameters: {
      'subject': subject,
      'body': body,
    },
  );

  // Launch the default email app with the pre-filled email
  launch(emailUri.toString());
}

