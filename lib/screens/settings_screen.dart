import 'package:dash_flags/dash_flags.dart';
import 'package:donation_app_v1/auth_service.dart';
import 'package:donation_app_v1/const_values/settings_page_values.dart';
import 'package:donation_app_v1/const_values/title_values.dart';
import 'package:donation_app_v1/enums/currency_enum.dart';
import 'package:donation_app_v1/enums/drawer_enum.dart';
import 'package:donation_app_v1/enums/language_enum.dart';
import 'package:donation_app_v1/models/drawer_model.dart';
import 'package:donation_app_v1/models/settings_model.dart'; // Hive-enabled Settings model.
import 'package:donation_app_v1/providers/provider.dart';
import 'package:donation_app_v1/screens/change_email_screen.dart';
import 'package:donation_app_v1/screens/change_username_screen.dart';
import 'package:donation_app_v1/screens/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dash_flags/dash_flags.dart';

final _supabaseClient = Supabase.instance.client;

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _hasImageError = false;

  @override
  void initState(){
    super.initState();
    final profileProvider=Provider.of<ProfileProvider>(context,listen: false);
    profileProvider.updateSettings(getCurrentSettingsFromHive());

  }
  @override
  void dispose() {
    // This will be called when the user leaves the page
    print("User is leaving settings page. Saving changes...");
    updateProfileSettings(); // Save settings
    super.dispose();
  }
  String getCurrentLanguage()  {
    // Ensure that the Hive box is open. If already open, this returns the box immediately.
    final Box<Settings> settingsBox = Hive.box<Settings>('settingsBox');

    // Retrieve stored settings or use default settings if none are stored.
    final Settings settings = settingsBox.get('userSettings', defaultValue: Settings.defaultSettings)!;

    // Return the current language as an enum.
    return  settings.language;
  }


  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final settings = profileProvider.profile!.settings;
    bool isDarkMode = settings.theme == "dark";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          PageTitles.getTitle(profileProvider.profile!.settings.language, 'settings_page_title'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.teal.shade700,
        elevation: 4,
        centerTitle: true,
      ),
      drawer: DonationAppDrawer(drawerIndex: DrawerItem.settings.index),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade900,Colors.tealAccent.shade400 ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildProfileSection(),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryHeader(SettingsLabels.getLabel(getCurrentLanguage(), 'profile_settings_section')),
                        _buildSettingsItem(SettingsLabels.getLabel(getCurrentLanguage(), 'username_button'), Icons.account_circle, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChangeUsernameScreen()),
                          );
                        },),
                        // _buildSettingsItem(SettingsLabels.getLabel(getCurrentLanguage(), 'email_button'), Icons.email, () {
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(builder: (context) => ChangeEmailPage()),
                        //   );
                        // },),
                        _buildSettingsItem(SettingsLabels.getLabel(getCurrentLanguage(), '6-Digit Code'), Icons.password_outlined, () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => LockScreen(isAuthCheck: false,isLockSetup: true),));
                        },),
                        SizedBox(height: 20),
                        Divider(thickness: 1.2, color: Colors.grey.shade300),
                        SizedBox(height: 20),

                        _buildCategoryHeader(SettingsLabels.getLabel(getCurrentLanguage(), 'app_settings_section')),
                        _buildSettingsSwitch(
                          title: SettingsLabels.getLabel(getCurrentLanguage(), 'dark_mode'),
                          value: isDarkMode,
                          icon: Icons.dark_mode,
                          onChanged: (val) {
                            final newSettings = settings.copyWith(theme: val ? "dark" : "light");
                            _updateSettings(newSettings, profileProvider);
                          },
                        ),
                        SizedBox(height: 16),
                        _buildLanguageDropdown(profileProvider),
                        SizedBox(height: 16),
                        _buildCurrencyDropdown(profileProvider),
                        // SizedBox(height: 16),
                        // _buildFontSizeSlider(profileProvider),

                        SizedBox(height: 20),
                        Divider(thickness: 1.2, color: Colors.grey.shade300),
                        SizedBox(height: 20),

                        _buildCategoryHeader(SettingsLabels.getLabel(getCurrentLanguage(), 'notifications_section')),
                        _buildSettingsSwitch(
                          title: SettingsLabels.getLabel(getCurrentLanguage(), 'enable_notifications'),
                          value: settings.notificationsEnabled,
                          icon: Icons.notifications,
                          onChanged: (val) {
                            final newSettings = settings.copyWith(notificationsEnabled: val);
                            _updateSettings(newSettings, profileProvider);
                          },
                        ),
                        _buildNotificationSoundDropdown(profileProvider),

                        SizedBox(height: 20),
                        Divider(thickness: 1.2, color: Colors.grey.shade300),
                        SizedBox(height: 20),

                        _buildCategoryHeader(SettingsLabels.getLabel(getCurrentLanguage(), 'privacy_security_section')),
                        _buildSettingsSwitch(
                          title: SettingsLabels.getLabel(getCurrentLanguage(), 'privacy_mode'),
                          value: settings.privacyMode,
                          icon: Icons.lock,
                          onChanged: (val) {
                            final newSettings = settings.copyWith(privacyMode: val);
                            _updateSettings(newSettings, profileProvider);
                          },
                        ),
                        _buildAccentColorDropdown(profileProvider),
                        SizedBox(height: 16),
                        _buildLayoutModeDropdown(profileProvider),

                        SizedBox(height: 20),
                        Divider(thickness: 1.2, color: Colors.grey.shade300),
                        SizedBox(height: 20),

                        _buildCategoryHeader(SettingsLabels.getLabel(getCurrentLanguage(), 'account_section')),
                        _buildSettingsItem(SettingsLabels.getLabel(getCurrentLanguage(), 'privacy_policy_button'), Icons.privacy_tip, _showPrivacyPolicy),
                        _buildSettingsItem(SettingsLabels.getLabel(getCurrentLanguage(), 'terms_conditions_button'), Icons.description, _showTerms),

                        SizedBox(height: 20),
                        Divider(thickness: 1.2, color: Colors.grey.shade300),
                        SizedBox(height: 20),

                        _buildSettingsItem(SettingsLabels.getLabel(getCurrentLanguage(), 'about_button'), Icons.info, _showAboutDialog),
                        _buildSettingsItem(SettingsLabels.getLabel(getCurrentLanguage(), 'logout_button'), Icons.exit_to_app, _logout, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade800,
        ),
      ),
    );
  }
  // Profile Section
  Widget _buildProfileSection() {
    final user = _supabaseClient.auth.currentUser;
    final username = user?.userMetadata?['username'] ?? 'User';
    final email = user?.email ?? 'tempUser@example.com';
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

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
            foregroundImage: _hasImageError
                ? AssetImage('assets/images/default.png')
                : NetworkImage(profileProvider.profile!.imageUrl) as ImageProvider,
            onForegroundImageError: (exception, stackTrace) {
              setState(() => _hasImageError = true);
              print("Error loading image: $exception");
            },
            child: _hasImageError
                ? Text(
              (user?.userMetadata?['username'] ?? "User")[0].toUpperCase(),
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
              Text(username, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(email, style: TextStyle(fontSize: 14, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  // Switch widget used for toggles.
  Widget _buildSettingsSwitch({
    required String title,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      secondary: Icon(icon, color: Colors.green.shade700),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.green,
    );
  }

  // General list item widget.
  Widget _buildSettingsItem(String title, IconData icon, VoidCallback onTap, {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  // Language dropdown widget.

  Widget _buildLanguageDropdown(ProfileProvider profileProvider) {
    Languages currentLanguage = Languages.values.firstWhere((element) => element.code == profileProvider.profile!.settings.language,);

    return Row(
      children: [
        Icon(Icons.language, color: Colors.green.shade700),
        SizedBox(width: 16),
        Flexible(
          child: DropdownButtonFormField<Languages>(
            decoration: InputDecoration(
              labelText: SettingsLabels.getLabel(getCurrentLanguage(), 'select_language_hint'),
              labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            value: currentLanguage,
            dropdownColor: Colors.white,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.teal, size: 28),
            style: TextStyle(fontSize: 16, color: Colors.black87),
            items: Languages.values.map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Row(
                  children: [
                    Text(lang.code),
                    SizedBox(width: 8),
                    Text(
                      lang.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis, // Adds "..." if text overflows
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final newSettings = profileProvider.profile!.settings.copyWith(language: value.code);
                _updateSettings(newSettings, profileProvider);
              }
            },
          ),
        ),
      ],
    );
  }

  // Currency dropdown widget.
  Widget _buildCurrencyDropdown(ProfileProvider profileProvider) {
    Currency currentCurrency = Currency.values.firstWhere((element) => element.code == profileProvider.profile!.settings.currency,);

    return Row(
      children: [
        Icon(Icons.attach_money, color: Colors.green.shade700),
        SizedBox(width: 16),
        Flexible(
          child: DropdownButtonFormField<Currency>(
            decoration: InputDecoration(
              labelText: SettingsLabels.getLabel(getCurrentLanguage(), 'select_currency_hint'),
              labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            value: currentCurrency,
            dropdownColor: Colors.white,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.teal, size: 28),
            style: TextStyle(fontSize: 16, color: Colors.black87),
            items: Currency.values.map((cur) {
              return DropdownMenuItem(
                value: cur,
                child: Row(
                  children: [
                    Text(
                      cur.symbol,
                      style: TextStyle(fontSize: 16, color: Colors.teal, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 150,// Allows text to wrap instead of overflowing
                      child: Text(
                        cur.getString,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis, // Adds "..." if text overflows
                      ),
                    ),
                  ],
                ),
              );

            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final newSettings = profileProvider.profile!.settings.copyWith(currency: value.code);
                _updateSettings(newSettings, profileProvider);
              }
            },
          ),
        ),

      ],
    );
  }

  // Font size slider widget.
  Widget _buildFontSizeSlider(ProfileProvider profileProvider) {
    double currentFontSize = profileProvider.profile!.settings.fontSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(SettingsLabels.getLabel(getCurrentLanguage(), 'font_size'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Slider(
          min: 10.0,
          max: 30.0,
          divisions: 20,
          label: currentFontSize.toStringAsFixed(1),
          value: currentFontSize,
          onChanged: (val) {
            final newSettings = profileProvider.profile!.settings.copyWith(fontSize: val);
            _updateSettings(newSettings, profileProvider);
          },
        ),
      ],
    );
  }

  // Accent color dropdown widget.
  Widget _buildAccentColorDropdown(ProfileProvider profileProvider) {
    // Define some example colors with their string representation.
    final Map<String, int> colorOptions = {
      'Teal': Colors.teal.value,
      'Blue': Colors.blue.value,
      'Red': Colors.red.value,
      'Green': Colors.green.value,
    };

    // Find the current color name by matching the value.
    String currentColorName = colorOptions.entries
        .firstWhere((entry) => entry.value == profileProvider.profile!.settings.accentColor,
        orElse: () => MapEntry('Teal', Colors.teal.value))
        .key;

    return Row(
      children: [
        Icon(Icons.color_lens, color: Colors.green.shade700),
        SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: SettingsLabels.getLabel(getCurrentLanguage(), 'accent_color_hint'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            value: currentColorName,
            items: colorOptions.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.key),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final newSettings = profileProvider.profile!.settings.copyWith(accentColor: colorOptions[value]);
                _updateSettings(newSettings, profileProvider);
              }
            },
          ),
        ),
      ],
    );
  }

  // Notification sound dropdown widget.
  Widget _buildNotificationSoundDropdown(ProfileProvider profileProvider) {
    final List<String> sounds = ['default', 'chime', 'alert'];
    String currentSound = profileProvider.profile!.settings.notificationSound;

    return Row(
      children: [
        Icon(Icons.music_note, color: Colors.green.shade700),
        SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: SettingsLabels.getLabel(getCurrentLanguage(), 'notification_sound_hint'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            value: currentSound,
            items: sounds.map((sound) {
              return DropdownMenuItem(
                value: sound,
                child: Text(sound.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final newSettings = profileProvider.profile!.settings.copyWith(notificationSound: value);
                _updateSettings(newSettings, profileProvider);
              }
            },
          ),
        ),
      ],
    );
  }

  // Layout mode dropdown widget.
  Widget _buildLayoutModeDropdown(ProfileProvider profileProvider) {
    final List<String> layouts = ['compact', 'comfortable'];
    String currentLayout = profileProvider.profile!.settings.layoutMode;

    return Row(
      children: [
        Icon(Icons.view_agenda, color: Colors.green.shade700),
        SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText:SettingsLabels.getLabel(getCurrentLanguage(), 'layout_mode_hint'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            value: currentLayout,
            items: layouts.map((layout) {
              return DropdownMenuItem(
                value: layout,
                child: Text(layout[0].toUpperCase() + layout.substring(1)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final newSettings = profileProvider.profile!.settings.copyWith(layoutMode: value);
                _updateSettings(newSettings, profileProvider);
              }
            },
          ),
        ),
      ],
    );
  }

  // About dialog
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: "Donation App",
      applicationVersion: "1.0.0",
      applicationLegalese: "© 2025 FlexCode Studios",
    );
  }

  // Privacy Policy dialog
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Privacy Policy"),
        content: SingleChildScrollView(child: Text("Your privacy policy details go here...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close")),
        ],
      ),
    );
  }

  // Terms dialog
  void _showTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Terms & Conditions"),
        content: SingleChildScrollView(child: Text("Your terms and conditions details go here...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close")),
        ],
      ),
    );
  }

  Future<void> updateProfileSettings() async {
    final supabase = Supabase.instance.client;
    final profileProvider=Provider.of<ProfileProvider>(context,listen: false);
    final response = await supabase
        .from('profiles') // Ensure this is your correct table name
        .update({'settings': profileProvider.profile!.settings.toJson()})
        .eq('username', supabase.auth.currentUser!.userMetadata!['username']); // Match the correct user by ID

    if (response.error != null) {
      print("Error updating settings: ${response.error!.message}");
    } else {
      print("Settings updated successfully!");
    }
  }

  // --- Hive Integration Helpers ---
  Future<void> updateSettingsInHive(Settings newSettings) async {
    final settingsBox = Hive.box<Settings>('settingsBox');
    await settingsBox.put('userSettings', newSettings);
  }

  Settings getCurrentSettingsFromHive() {
    final settingsBox = Hive.box<Settings>('settingsBox');
    return settingsBox.get('userSettings', defaultValue: Settings.defaultSettings)!;
  }

  // Helper method to update settings in both Hive and Provider.
  void _updateSettings(Settings newSettings, ProfileProvider profileProvider) {
    updateSettingsInHive(newSettings);
    profileProvider.updateSettings(newSettings);
    updateProfileSettings();
  }

  // Logout action
  void _logout() async{
    print("User Logged Out");
    _supabaseClient.auth.signOut();
    final authBox = await Hive.openBox<AuthService>('authBox');
    AuthService().saveToken(authBox, false);
    AuthService.getToken(authBox)! ? Navigator.pushNamedAndRemoveUntil(context, '/lock', (Route<dynamic> route) => false) : Navigator.pushNamedAndRemoveUntil(context, '/signIn', (Route<dynamic> route) => false);
  }
}
