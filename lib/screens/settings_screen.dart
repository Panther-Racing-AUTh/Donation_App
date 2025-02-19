import 'package:donation_app_v1/models/drawer_model.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:donation_app_v1/models/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Example state variable for Dark Mode; you might later store this in the provider as well.
  bool _darkMode = false;
  bool _hasImageError = false;


  @override
  Widget build(BuildContext context) {
    // Listen to the provider so that UI rebuilds when the profile changes.
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        centerTitle: true,
      ),
      drawer: DonationAppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade700, Colors.tealAccent.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            _buildProfileSection(_hasImageError),
            Expanded(
              child: Card(
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      _buildSettingsSwitch(
                        title: "Enable Notifications",
                        value: profileProvider.profile!.settings.notificationsEnabled,
                        icon: Icons.notifications,
                        onChanged: (val) {
                          // Update the settings using copyWith and call updateSettings in your provider.
                          profileProvider.updateSettings(
                            profileProvider.profile!.settings.copyWith(
                              notificationsEnabled: val,
                            ),
                          );
                        },
                      ),
                      _buildSettingsSwitch(
                        title: "Dark Mode",
                        value: _darkMode,
                        icon: Icons.dark_mode,
                        onChanged: (val) {
                          setState(() {
                            _darkMode = val;
                          });
                        },
                      ),
                      Divider(),
                      _buildSettingsItem("About", Icons.info, _showAboutDialog),
                      _buildSettingsItem("Logout", Icons.exit_to_app, _logout, color: Colors.red),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(    bool _hasImageError) {
    final user = _supabaseClient.auth.currentUser;
    final username = user?.userMetadata?['username'] ?? 'User';
    final email = user?.email ?? 'tempUser@example.com';

    ProfileProvider profileProvider=Provider.of<ProfileProvider>(context,listen: false);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.teal.shade700,
            foregroundImage: _hasImageError ? null : NetworkImage(profileProvider.profile!.imageUrl),
            onForegroundImageError: (exception, stackTrace) {
              // When error occurs, update state to show fallback text.
              setState(() {
                _hasImageError = true;
              });
              print("Error loading image: $exception");
            },
            child: _hasImageError
                ? Text(
              ( _supabaseClient.auth.currentUser!.userMetadata!['username'] ?? "User" )[0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: Colors.white,
              ),
            )
                : null,
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                email,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSwitch({
    required String title,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      secondary: Icon(
        icon,
        color: Colors.green.shade700,
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.green,
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, VoidCallback onTap, {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: "Donation App",
      applicationVersion: "1.0.0",
      applicationLegalese: "© 2025 FlexCode Studios",
    );
  }

  void _logout() {
    print("User Logged Out");
    Navigator.pop(context);
  }
}
