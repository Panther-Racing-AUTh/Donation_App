import 'package:donation_app_v1/auth_service.dart';
import 'package:donation_app_v1/const_values/drawer_values.dart';
import 'package:donation_app_v1/models/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../enums/drawer_enum.dart';
import '../providers/provider.dart';
import '../screens/about_us_screen.dart';
import '../screens/help_&_support_screen.dart';
import '../screens/privacy_&_security_screen.dart';
import '../screens/partners_screen.dart';
import '../screens/profile_screen.dart';
import '../qr_code_scanner.dart';
import '../screens/settings_screen.dart';
import '../screens/terms_&_conditions_screen.dart';

final _supabaseClient = Supabase.instance.client;

class DonationAppDrawer extends StatelessWidget {
  final String topDonatorUsername;
  final int drawerIndex;

  const DonationAppDrawer({
    Key? key,
    this.topDonatorUsername = '',
    required this.drawerIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = _supabaseClient.auth.currentUser;
    final username = user?.userMetadata?['username'] ?? 'User';
    final email = user?.email ?? 'tempUser@example.com';
    final isTopDonator = username == topDonatorUsername;
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final profileImage = profileProvider.profile?.imageUrl ?? 'assets/images/default.png';
    final langCode = profileProvider.profile!.settings.language;
    return Drawer(
      backgroundColor: Colors.grey.shade100, // Light background for contrast
      child: Column(
        children: [
          _buildUserHeader(username, email, profileImage),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSection(context, MenuTiles.getTile(langCode, 'main_category'), [
                  _buildNavItem(context, DrawerItem.home, drawerIndex, isTopDonator),
                  _buildNavItem(context, DrawerItem.profile, drawerIndex, isTopDonator),
                  _buildNavItem(context, DrawerItem.qrScanner, drawerIndex, isTopDonator),
                ]),

                _buildSection(context, MenuTiles.getTile(langCode, 'settings_category'), [
                  _buildNavItem(context, DrawerItem.settings, drawerIndex, isTopDonator),
                  _buildNavItem(context, DrawerItem.lock, drawerIndex, isTopDonator),
                  _buildNavItem(context, DrawerItem.privacy, drawerIndex, isTopDonator),
                  _buildNavItem(context, DrawerItem.terms, drawerIndex, isTopDonator),
                ]),

                _buildSection(context, MenuTiles.getTile(langCode, 'support_info_category'), [
                  _buildNavItem(context, DrawerItem.partners, drawerIndex, isTopDonator),
                  _buildNavItem(context, DrawerItem.support, drawerIndex, isTopDonator),
                  _buildNavItem(context, DrawerItem.feedback, drawerIndex, isTopDonator),
                  _buildNavItem(context, DrawerItem.about, drawerIndex, isTopDonator),
                ]),

                Divider(),

                _buildLogoutButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

// 🎨 Stylish User Header
  Widget _buildUserHeader(String username, String email, String imageUrl) {
    return UserAccountsDrawerHeader(
      accountName: Text(username, style: const TextStyle(fontSize: 18)),
      accountEmail: Text(email, style: const TextStyle(fontSize: 16)),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.teal.shade700,
        foregroundImage: imageUrl.startsWith('http') ? NetworkImage(imageUrl) : AssetImage(imageUrl) as ImageProvider,
        child: Text(username[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.white)),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal, Colors.green], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
    );
  }


// 🏆 Modernized Section Wrapper
  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                gradient: LinearGradient(colors: [Colors.teal.shade300, Colors.green.shade400]),
              ),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Column(children: items),
          ],
        ),
      ),
    );
  }

// ✨ Styled Nav Items with Hover Effect
  Widget _buildNavItem(BuildContext context, DrawerItem item, int drawerIndex, bool isTopDonator) {
    final isSelected = drawerIndex == item.index;

    return ListTile(
      leading: Icon(
        item.icon,
        color: isSelected ? Colors.white : Colors.teal.shade800,
        size: 26,
      ),
      title: Text(
        item.name(context),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
      tileColor: isSelected ? Colors.teal.shade800.withOpacity(0.5) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      onTap: () => _navigate(context, item, drawerIndex, isTopDonator),
    );
  }


// 🚀 Stylish Logout Button
  Widget _buildLogoutButton(BuildContext context) {
    final profileProvider=Provider.of<ProfileProvider>(context,listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: () async{

          _supabaseClient.auth.signOut();
          final authBox = await Hive.openBox<AuthService>('authBox');
          AuthService().saveToken(authBox, false);
          AuthService.getToken(authBox)! ? Navigator.pushNamedAndRemoveUntil(context, '/lock', (Route<dynamic> route) => false) : Navigator.pushNamedAndRemoveUntil(context, '/signIn', (Route<dynamic> route) => false);
        },
        icon: Icon(Icons.logout, size: 22),
        label: Text(MenuTiles.getTile(profileProvider.profile!.settings.language, 'logout_tile'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _navigate(BuildContext context, DrawerItem item, int drawerIndex, bool isTopDonator) {
    if (item == DrawerItem.logout) {
      _supabaseClient.auth.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/signIn', (route) => false);
      return;
    }

    // Close the drawer
    Navigator.pop(context);

    if (drawerIndex == item.index) return;

    // drawerProvider.updateDrawerIndex(item.index);
    final pageBuilder = drawerRoutes[item];

    if (pageBuilder != null) {
      Widget page = pageBuilder(context);

      // Handle ProfilePage separately since it requires `isTopDonator`
      if (item == DrawerItem.profile) {
        page = ProfilePage(isTopDonator: isTopDonator);
      }
      if(item == DrawerItem.qrScanner){
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        return;
      }

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));

      // drawerProvider.updateDrawerIndex(item.index);
    }
  }
}
