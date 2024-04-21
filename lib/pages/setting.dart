import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tugas1_login/pages/profile.dart';
import 'package:url_launcher/url_launcher.dart';
import '../backend/functions.dart';
import '../backend/user_provider.dart';
import 'package:tugas1_login/main.dart';

class LanguageSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslations()['select_language']!),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('English'),
            onTap: () {
              // Set selected language to English
              // You can implement language selection logic here
              UserProvider userProvider = Provider.of<UserProvider>(
                  context, listen: false);
              userProvider.setLangKey('en');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyApp()),
              );
              // Close language selection page
            },
          ),
          ListTile(
            title: Text('كوردى'),
            onTap: () {
              // Set selected language to Spanish
              // You can implement language selection logic here
              UserProvider userProvider = Provider.of<UserProvider>(
                  context, listen: false);
              userProvider.setLangKey('ku');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyApp()),
              );
            },
          ),
          ListTile(
            title: Text('عربي'),
            onTap: () {
              // Set selected language to Spanish
              // You can implement language selection logic here
              UserProvider userProvider = Provider.of<UserProvider>(
                  context, listen: false);
              userProvider.setLangKey('ar');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyApp()),
              );
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
        title: Text(getTranslations()['change_password']!),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getTranslations()['current_password']!,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText:getTranslations()['enter_current_password']!,
              ),
            ),
            SizedBox(height: 16),
            Text(
              getTranslations()['new_password']!,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText:getTranslations()['enter_new_password']!,
              ),
            ),
            SizedBox(height: 16),
            Text(
              getTranslations()['confirm_new_password']!,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: getTranslations()['confirm_new_password_description']!,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _handleChangePassword();
              },
              child: Text(getTranslations()['save_changes']!),
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
      _showSnackBar(getTranslations()['fill_all_fields']!);
      return;
    }

    // Check if new password matches the confirm password
    if (newPassword != confirmPassword) {
      _showSnackBar(getTranslations()['passwords_do_not_match']!);
      return;
    }

    // Implement your logic for changing the password here

    // Clear text fields after successful password change
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    _showSnackBar(getTranslations()['password_changed_successfully']!);
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
        title: Text(getTranslations()['settings']!),
      ),
      body: ListView(
        children: [
          _buildHeader(getTranslations()['account']!),
          _buildListItem(Icons.person,getTranslations()['edit_profile']! , () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditProfilePage()),
            );
          }),

          _buildListItem(Icons.lock,getTranslations()['change_password']!, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChangePasswordPage()),
            );
          }),
          _buildDivider(),
          _buildHeader(getTranslations()['notifications']!),
          _buildSwitchListItem(getTranslations()['receive_notifications']!, true, (bool value) {
            // Handle switch value change
          }),
          _buildDivider(),
          _buildHeader(getTranslations()['app_settings']!),
          _buildListItem(Icons.language, getTranslations()['language']!, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LanguageSelectionPage()), // Navigate to LanguageSelectionPage
            );
          }),
          _buildDivider(),
          _buildHeader(getTranslations()['support']!),
          _buildListItem(Icons.help, getTranslations()['help_and_feedback']!, () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(getTranslations()['help_and_feedback']!),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Icon(Icons.contact_support),
                        title: Text(getTranslations()['contact_support']!),
                        onTap: () {
                          _contactSupport(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.bug_report),
                        title: Text(getTranslations()['report_an_issue']!),
                        onTap: () {
                          // Implement report issue functionality
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.feedback),
                        title: Text(getTranslations()['provide_feedback']!),
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
          _buildListItem(Icons.info, getTranslations()['about']! , () {
            showAboutDialog(
              context: context,
              applicationName: 'PharmAssist',
              applicationVersion: '1.0.0', // Your app version
              applicationLegalese: '© 2024 Cihan University\n', // Your company name or legal information
              children: [
                // Additional information about your app
                Text(getTranslations()['about_description']!),
              ],
            );
          }),
          _buildDivider(),
          _buildListItem(Icons.exit_to_app, getTranslations()['log_out']!, () {
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

