import 'package:donation_app_v1/providers/provider.dart';
import 'package:donation_app_v1/screens/profile_screen.dart';
import 'package:donation_app_v1/qr_code_scanner.dart';
import 'package:donation_app_v1/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client

class DonationAppDrawer extends StatefulWidget {
  final String topDonatorUsername;
  DonationAppDrawer({Key? key, this.topDonatorUsername = ''}) : super(key: key);

  @override
  State<DonationAppDrawer> createState() => _DonationAppDrawerState();
}

class _DonationAppDrawerState extends State<DonationAppDrawer> {
  @override
  Widget build(BuildContext context) {
    final user = _supabaseClient.auth.currentUser;
    final username = user?.userMetadata?['username'] ?? 'User';
    final email = user?.email ?? 'tempUser@example.com';
    bool _hasImageError = false;

    bool isTopDonator = username == widget.topDonatorUsername;
    ProfileProvider profileProvider =
    Provider.of<ProfileProvider>(context, listen: false);

    return Drawer(
      child: Column(
        children: [
          // User Info Header
          _buildUserHeader(username, email,_hasImageError),
          // Navigation Items
          Expanded(
            child: ListView(
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.home,
                  title: 'Home',
                  routeName: '/donation',
                  onTap: () => _navigate(context, '/donation'),
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.person,
                  title: 'Profile',
                  routeName: '/profile',
                  onTap: () {
                    // For pages without named routes, simply push via MaterialPageRoute.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfilePage(isTopDonator: isTopDonator),
                      ),
                    );
                  },
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.info,
                  title: 'About Us',
                  routeName: '/aboutUs',
                  onTap: () => _navigate(context, '/aboutUs'),
                ),
                const Divider(),
                _buildNavItem(
                  context: context,
                  icon: Icons.qr_code_scanner,
                  title: 'Scan QR',
                  // No named route provided – fallback to home if needed.
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => QrCodeScanner()),
                    );
                  },
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.feedback,
                  title: 'Feedback',
                  routeName: '/feedback',
                  onTap: () => _navigate(context, '/feedback'),
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Settings',
                  routeName: '/settings',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  ),
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
  Widget _buildUserHeader(String username, String email,bool _hasImageError) {
    ProfileProvider profileProvider =
    Provider.of<ProfileProvider>(context, listen: false);

    return UserAccountsDrawerHeader(
      accountName: Text(
        username,
        style: const TextStyle(fontSize: 18),
      ),
      accountEmail: Text(
        email,
        style: const TextStyle(fontSize: 16),
      ),
      currentAccountPicture:  CircleAvatar(
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Colors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // Builds a Navigation Item with optional route name to check current route.
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? routeName,
    required VoidCallback onTap,
  }) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isCurrent =
        routeName != null && currentRoute != null && currentRoute == routeName;

    return ListTile(
      tileColor: isCurrent ? null : null,
      leading: Icon(icon, color: isCurrent ? Colors.teal : Colors.teal),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isCurrent ? Colors.black : Colors.black,
        ),
      ),
      onTap: () {
        if (routeName != null && isCurrent) {
          // If already on that route, fallback to home unless it's already home.
          if (routeName != '/donation') {
            Navigator.pushReplacementNamed(context, '/donation');
          } else {
            Navigator.pop(context);
          }
        } else {
          onTap();
        }
      },
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
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/signIn',
                (Route<dynamic> route) => false, // Remove all routes.
          );
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
void _navigate(BuildContext context, String targetRoute) {
  final currentRoute = ModalRoute.of(context)?.settings.name;
  // If we're already on the target route:
  if (currentRoute == targetRoute) {
    // If the target is not the home page, fallback to the home page.
    if (targetRoute != '/donation') {
      Navigator.pushReplacementNamed(context, '/donation');
    } else {
      // If we're on home, simply close the drawer.
      Navigator.pop(context);
    }
  } else {
    // Otherwise, navigate to the target route.
    Navigator.pushReplacementNamed(context, targetRoute);
  }
}
