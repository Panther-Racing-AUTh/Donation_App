import 'package:donation_app_v1/const_values/about_us_page_values.dart';
import 'package:donation_app_v1/const_values/title_values.dart';
import 'package:donation_app_v1/enums/drawer_enum.dart';
import 'package:donation_app_v1/icons/donation_icons_icons.dart';
import 'package:donation_app_v1/models/drawer_model.dart';
import 'package:donation_app_v1/models/settings_model.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mailto/mailto.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  Future<void> _launchInAppWithBrowserOptions(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    )) {
      throw Exception('Could not launch $url');
    }
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
    final profileProvider= Provider.of<ProfileProvider>(context,listen: false);

    return Scaffold(
      drawer: DonationAppDrawer(drawerIndex: DrawerItem.about.index,),
      appBar: AppBar(
        title: Text(PageTitles.getTitle(profileProvider.profile!.settings.language, 'about_us_page_title')),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100.withOpacity(0.5), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 250,
                child: Stack(
                  children: [
                    Container(
                      height: 250,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/panther_racing_team.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      height: 250,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        width: MediaQuery.of(context).size.width * .9,
                        child: const Text(
                          'Panther Racing Team AUTH',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSection(
                title: AboutUsLabels.getLabel(0, getCurrentLanguage(), 'title'),
                content: AboutUsLabels.getLabel(0, getCurrentLanguage(), 'content'),
                icon: Icons.lightbulb_outline,
              ),
              const Divider(),
              _buildSection(
                title: AboutUsLabels.getLabel(1, getCurrentLanguage(), 'title'),
                content: AboutUsLabels.getLabel(1, getCurrentLanguage(), 'content'),
                icon: Icons.emoji_events_outlined,
              ),
              const Divider(),
              _buildSection(
                title: AboutUsLabels.getLabel(2, getCurrentLanguage(), 'title'),
                content: AboutUsLabels.getLabel(2, getCurrentLanguage(), 'content'),
                icon: Icons.flag_outlined,
              ),
              const Divider(),
              _buildSection(
                title: AboutUsLabels.getLabel(3, getCurrentLanguage(), 'title'),
                content: AboutUsLabels.getLabel(3, getCurrentLanguage(), 'content'),
                icon: Icons.volunteer_activism,
              ),
              const Divider(),
              _buildSection(
                title: AboutUsLabels.getLabel(4, getCurrentLanguage(), 'title'),
                content: AboutUsLabels.getLabel(4, getCurrentLanguage(), 'content'),
                icon: Icons.support,
              ),
              const Divider(),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(DonationIcons.instagram, color: Colors.pink.shade600,size: 30,),
                      onPressed: () => _launchInAppWithBrowserOptions(Uri.parse('https://instagram.com/panther_racing')),
                    ),
                    IconButton(
                      icon: Icon(DonationIcons.globe, color: Colors.blue.shade600,size: 30,),
                      onPressed: () => _launchInAppWithBrowserOptions(Uri.parse('https://pantherauth.gr')),
                    ),
                    IconButton(
                      icon: Icon(DonationIcons.email, color: Colors.green.shade600,size: 30,),
                      onPressed: () => _sendEmail('pantherracing@gmail.com','',''),
                    ),
                    IconButton(
                      icon: Icon(DonationIcons.youtube, color: Colors.red.shade600,size: 30,),
                      onPressed: () => _launchInAppWithBrowserOptions(Uri.parse('https://youtube.com/@pantheracingau')),
                    ),
                    IconButton(
                      icon: Icon(Icons.tiktok, color: Colors.black,size: 30,),
                      onPressed: () => _launchInAppWithBrowserOptions(Uri.parse('https://tiktok.com/@panther_racing')),
                    ),
                    IconButton(
                      icon: Icon(DonationIcons.linkedin, color: Colors.blueAccent,size: 30,),
                      onPressed: () => _launchInAppWithBrowserOptions(Uri.parse('https://gr.linkedin.com/company/panther-racing-auth')),
                    ),
                    IconButton(
                      icon: Icon(DonationIcons.github_circled, color: Colors.black,size: 30,),
                      onPressed: () => _launchInAppWithBrowserOptions(Uri.parse('https://github.com/Panther-Racing-AUTh')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
// Function to send an email
  Future<void> _sendEmail(String email,String subject ,String body) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=$subject&body=$body', //add subject and body here
    );
    await launchUrl(launchUri);
  }
  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: Colors.teal),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
