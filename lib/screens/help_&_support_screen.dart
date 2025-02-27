import 'package:donation_app_v1/const_values/help_support_page_values.dart';
import 'package:donation_app_v1/const_values/title_values.dart';
import 'package:donation_app_v1/enums/drawer_enum.dart';
import 'package:donation_app_v1/models/drawer_model.dart';
import 'package:donation_app_v1/models/settings_model.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher for email support

class HelpSupportPage extends StatefulWidget {
  @override
  _HelpSupportPageState createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final String supportEmail = "pantherracingauth@gmail.com";
  final String liveChatUrl = "https://yourwebsite.com/livechat"; // Update this with your actual chat URL

  // Function to launch email app
  void _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {'subject': 'Support Request'}, // Pre-filled subject
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      print("Could not open email app");
    }
  }

  // Function to open Live Chat
  void _openLiveChat() async {
    if (await canLaunchUrl(Uri.parse(liveChatUrl))) {
      await launchUrl(Uri.parse(liveChatUrl));
    } else {
      print("Could not open live chat");
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
      drawer: DonationAppDrawer(drawerIndex: DrawerItem.support.index,),
      appBar: AppBar(
        title: Text(PageTitles.getTitle(profileProvider.profile!.settings.language, 'help_support_page_title')),
        backgroundColor: Colors.teal.shade700,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade700,Colors.tealAccent.shade400 ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 20),
              _buildFAQSection(),
              SizedBox(height: 20),
              _buildContactSupport(),
            ],
          ),
        ),
      ),
    );
  }

  // Header Section
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            HelpSupportLabels.getHelpSupportLabel(getCurrentLanguage(), 'need_help_title'),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 5),
          Text(
            HelpSupportLabels.getHelpSupportLabel(getCurrentLanguage(), 'support_team_text'),
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // FAQ Section
  Widget _buildFAQSection() {


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          HelpSupportLabels.getHelpSupportLabel(getCurrentLanguage(), 'frequently_asked_questions_section'),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
        ),
        SizedBox(height: 10),
        Column(
          children: HelpSupportLabels.getFaqList().map((faq) => _buildExpandableFAQItem(faq[getCurrentLanguage()]!["question"]!, faq[getCurrentLanguage()]!["answer"]!)).toList(),
        ),
      ],
    );
  }

  Widget _buildExpandableFAQItem(String question, String answer) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal.shade700),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(answer, style: TextStyle(fontSize: 14, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  // Contact Support Section
  Widget _buildContactSupport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(HelpSupportLabels.getHelpSupportLabel(getCurrentLanguage(), 'need_more_help_section'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
        SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(Icons.email, color: Colors.teal.shade700),
                  title: Text(HelpSupportLabels.getHelpSupportLabel(getCurrentLanguage(), 'email_support')),
                  subtitle: Text(supportEmail),
                  onTap: _sendEmail, // Opens email app
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.chat, color: Colors.teal.shade700),
                  title: Text(HelpSupportLabels.getHelpSupportLabel(getCurrentLanguage(), 'live_chat')),
                  subtitle: Text(HelpSupportLabels.getHelpSupportLabel(getCurrentLanguage(), 'live_chat_text')),
                  onTap: _openLiveChat, // Opens live chat page
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
