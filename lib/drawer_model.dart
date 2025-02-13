import 'package:donation_app_v1/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client

class DonationAppDrawer extends StatelessWidget {
  String topDonatorUsername;

  DonationAppDrawer({Key? key,this.topDonatorUsername=''}) : super(key: key);




  @override
  Widget build(BuildContext context) {
    final user = _supabaseClient.auth.currentUser;
    final username = user?.userMetadata?['username'] ?? 'User';
    final email = user?.email ?? 'tempUser@example.com';
    bool isTopDonator=username == topDonatorUsername;

    return Drawer(
      child: Column(
        children: [
          // User Info Header
          _buildUserHeader(username, email),

          // Navigation Items
          Expanded(
            child: ListView(
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () => Navigator.pushReplacementNamed(context, '/donation'),
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.person,
                  title: 'Profile', // Profile Button
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(isTopDonator: isTopDonator,),)),
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.info,
                  title: 'About Us',
                  onTap: () => Navigator.pushReplacementNamed(context, '/aboutUs'),
                ),
                const Divider(),
                _buildNavItem(
                  context: context,
                  icon: Icons.feedback,
                  title: 'Feedback',
                  onTap: () => Navigator.pushReplacementNamed(context, '/feedback'),
                ),
              ],
            ),
          ),

          // Logout Button
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  // Builds the User Info Header
  Widget _buildUserHeader(String username, String email) {
    return UserAccountsDrawerHeader(
      accountName: Text(
        username,
        style: const TextStyle(fontSize: 18),
      ),
      accountEmail: Text(
        email,
        style: const TextStyle(fontSize: 16),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.teal.shade700,
        child: Text(
          username[0].toUpperCase(), // Initial of the username
          style: const TextStyle(fontSize: 28, color: Colors.white),
        ),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Colors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // Builds a Navigation Item
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal.shade700),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  // Builds the Logout Button
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          _supabaseClient.auth.signOut();
          Navigator.pushReplacementNamed(context, '/');
        },
        child: Row(
          children: const [
            Icon(Icons.logout, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
