import 'package:donation_app_v1/const_values/drawer_values.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:donation_app_v1/screens/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:donation_app_v1/qr_code_scanner.dart';
import 'package:donation_app_v1/screens/about_us_screen.dart';
import 'package:donation_app_v1/screens/donations_screen.dart';
import 'package:donation_app_v1/screens/feedback_screen.dart';
import 'package:donation_app_v1/screens/help_&_support_screen.dart';
import 'package:donation_app_v1/screens/privacy_&_security_screen.dart';
import 'package:donation_app_v1/screens/partners_screen.dart';
import 'package:donation_app_v1/screens/profile_screen.dart';
import 'package:donation_app_v1/screens/settings_screen.dart';
import 'package:donation_app_v1/screens/terms_&_conditions_screen.dart';
import 'package:provider/provider.dart';

enum DrawerItem {
  home,
  profile,
  qrScanner,
  feedback,
  partners,
  settings,
  lock,
  privacy,
  support,
  terms,
  about,
  logout
}

extension DrawerItemExtension on DrawerItem {
  int getInt() {
    return index; // Returns the index of the enum item
  }

  String name(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final langCode = profileProvider.profile!.settings.language;

    switch (this) {
      case DrawerItem.home:
        return MenuTiles.getTile(langCode, 'home_tile');
      case DrawerItem.profile:
        return MenuTiles.getTile(langCode, 'profile_tile');
      case DrawerItem.qrScanner:
        return MenuTiles.getTile(langCode, 'qr_tile');
      case DrawerItem.feedback:
        return MenuTiles.getTile(langCode, 'feedback_tile');
      case DrawerItem.partners:
        return MenuTiles.getTile(langCode, 'partners_tile');
      case DrawerItem.settings:
        return MenuTiles.getTile(langCode, 'settings_tile');
      case DrawerItem.lock:
        return MenuTiles.getTile(langCode, 'lock_tile');
      case DrawerItem.privacy:
        return MenuTiles.getTile(langCode, 'privacy_security_tile');
      case DrawerItem.support:
        return MenuTiles.getTile(langCode, 'help_support_tile');
      case DrawerItem.terms:
        return MenuTiles.getTile(langCode, 'terms_conditions_tile');
      case DrawerItem.about:
        return MenuTiles.getTile(langCode, 'about_us_tile');
      case DrawerItem.logout:
        return MenuTiles.getTile(langCode, 'logout_tile');
    }
  }

  IconData get icon {
    switch (this) {
      case DrawerItem.home:
        return Icons.home;
      case DrawerItem.profile:
        return Icons.person;
      case DrawerItem.qrScanner:
        return Icons.qr_code_scanner;
      case DrawerItem.feedback:
        return Icons.feedback;
      case DrawerItem.partners:
        return Icons.people;
      case DrawerItem.settings:
        return Icons.settings;
      case DrawerItem.lock:
        return Icons.password_outlined;
      case DrawerItem.privacy:
        return Icons.lock;
      case DrawerItem.support:
        return Icons.help;
      case DrawerItem.terms:
        return Icons.description;
      case DrawerItem.about:
        return Icons.info;
      case DrawerItem.logout:
        return Icons.logout;
    }
  }
}

final Map<DrawerItem, Widget Function(BuildContext)> drawerRoutes = {
  DrawerItem.home: (_) => DonationsPage(), // Replace with HomeScreen()
  DrawerItem.profile: (context) => ProfilePage(isTopDonator: false), // Updated dynamically
  DrawerItem.qrScanner: (_) => QrCodeScanner(),
  DrawerItem.feedback: (_) => FeedbackScreen(), // Replace with FeedbackScreen()
  DrawerItem.partners: (_) => PartnersPage(),
  DrawerItem.settings: (_) => SettingsPage(),
  DrawerItem.lock: (_) => LockScreen(isAuthCheck: false, isLockSetup: false),
  DrawerItem.privacy: (_) => PrivacySecurityPage(),
  DrawerItem.support: (_) => HelpSupportPage(),
  DrawerItem.terms: (_) => TermsAndConditionsPage(),
  DrawerItem.about: (_) => AboutUsPage(),
};
