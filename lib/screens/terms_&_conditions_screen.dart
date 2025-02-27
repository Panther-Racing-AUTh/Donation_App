import 'package:donation_app_v1/const_values/terms_conditions_page_values.dart';
import 'package:donation_app_v1/const_values/title_values.dart';
import 'package:donation_app_v1/enums/drawer_enum.dart';
import 'package:donation_app_v1/models/drawer_model.dart';
import 'package:donation_app_v1/models/settings_model.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';



class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  @override
  Widget build(BuildContext context) {
    final profileProvider= Provider.of<ProfileProvider>(context,listen: false);

    String getCurrentLanguage()  {
      // Ensure that the Hive box is open. If already open, this returns the box immediately.
      final Box<Settings> settingsBox = Hive.box<Settings>('settingsBox');

      // Retrieve stored settings or use default settings if none are stored.
      final Settings settings = settingsBox.get('userSettings', defaultValue: Settings.defaultSettings)!;

      // Return the current language as an enum.
      return  settings.language;
    }

    Widget buildTermsSection(String languageCode) {
      List<Map<String, String>> terms = TermsConditionsLabels.getTermsAndConditions(getCurrentLanguage());

      return Column(
        children: [
          _buildSection(terms[0]['title']!, terms[0]['content']!),
          _buildSection(terms[1]['title']!, terms[1]['content']!),
          _buildSection(terms[2]['title']!, terms[2]['content']!),
          _buildSection(terms[3]['title']!, terms[3]['content']!),
          _buildSection(terms[4]['title']!, terms[4]['content']!),
          _buildSection(terms[5]['title']!, terms[5]['content']!),
        ],
      );
    }
    return Scaffold(
      drawer: DonationAppDrawer(drawerIndex: DrawerItem.terms.index,),
      appBar: AppBar(
        title: Text(PageTitles.getTitle(profileProvider.profile!.settings.language, 'terms_conditions_page_title')),
        backgroundColor: Colors.teal.shade700,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade900,Colors.tealAccent.shade400 ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),

                    _buildHeader(),
                    SizedBox(height: 20),
                    buildTermsSection(getCurrentLanguage()),
                    SizedBox(height: 80), // Extra space for button
                    // const Divider(height: 30, thickness: 1.2),
                    //
                    // // Privacy Policy Section
                    // Text(
                    //   "Privacy Policy",
                    //   style: TextStyle(
                    //     fontSize: 22,
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.teal.shade800,
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    // Container(
                    //   padding: const EdgeInsets.all(12),
                    //   decoration: BoxDecoration(
                    //     color: Colors.teal.shade50,
                    //     borderRadius: BorderRadius.circular(8),
                    //   ),
                    //   child: Text(
                    //     "We are committed to protecting your privacy. This app collects limited user data necessary for its functionality. "
                    //         "We do not share, sell, or distribute your personal information to third parties without your consent.\n\n"
                    //         "Please contact us at support@example.com for more information.",
                    //     style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    //   ),
                    // ),
                    // const Divider(height: 30, thickness: 1.2),
                    //
                    // // Licenses Section
                    // Text(
                    //   "Licenses",
                    //   style: TextStyle(
                    //     fontSize: 22,
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.teal.shade800,
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    // ExpansionTile(
                    //   leading: Icon(Icons.library_books, color: Colors.teal),
                    //   title: Text(
                    //     "Flutter",
                    //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    //   ),
                    //   children: [
                    //     Padding(
                    //       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    //       child: Text(
                    //         "Copyright 2025 The Flutter Authors. Licensed under the BSD-3-Clause License. "
                    //             "For more details, visit https://flutter.dev.",
                    //         style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // ExpansionTile(
                    //   leading: Icon(Icons.library_books, color: Colors.teal),
                    //   title: Text(
                    //     "Dart",
                    //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    //   ),
                    //   children: [
                    //     Padding(
                    //       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    //       child: Text(
                    //         "Copyright 2025 The Dart Authors. Licensed under the BSD License. "
                    //             "For more details, visit https://dart.dev.",
                    //         style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // ExpansionTile(
                    //   leading: Icon(Icons.library_books, color: Colors.teal),
                    //   title: Text(
                    //     "HTTP Library",
                    //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    //   ),
                    //   children: [
                    //     Padding(
                    //       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    //       child: Text(
                    //         "Copyright 2025 HTTP Maintainers. Licensed under the Apache 2.0 License. "
                    //             "For more details, visit https://pub.dev/packages/http.",
                    //         style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 20),
                    //
                    // // Acknowledgements Section
                    // Text(
                    //   "Acknowledgements",
                    //   style: TextStyle(
                    //     fontSize: 22,
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.teal.shade800,
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    // Container(
                    //   padding: const EdgeInsets.all(12),
                    //   decoration: BoxDecoration(
                    //     color: Colors.teal.shade50,
                    //     borderRadius: BorderRadius.circular(8),
                    //   ),
                    //   child: Text(
                    //     "This app is made possible thanks to the contributions of the open-source community and the following frameworks and libraries:\n\n"
                    //         "- Flutter\n"
                    //         "- Dart\n"
                    //         "- HTTP Library\n\n"
                    //         "We extend our gratitude to all contributors who made this app possible.",
                    //     style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    //   ),
                    // ),
                    // const SizedBox(height: 30),
                    //
                    // // Footer
                    // Center(
                    //   child: Text(
                    //     "Thank you for using our app!",
                    //     style: TextStyle(
                    //       fontSize: 16,
                    //       fontWeight: FontWeight.bold,
                    //       color: Colors.teal.shade700,
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(
                    //   height: 30,
                    // )
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(TermsConditionsLabels.getLabel(getCurrentLanguage(), 'button'), style: TextStyle(fontSize: 18,color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String getCurrentLanguage()  {
      // Ensure that the Hive box is open. If already open, this returns the box immediately.
      final Box<Settings> settingsBox = Hive.box<Settings>('settingsBox');

      // Retrieve stored settings or use default settings if none are stored.
      final Settings settings = settingsBox.get('userSettings', defaultValue: Settings.defaultSettings)!;

      // Return the current language as an enum.
      return  settings.language;
    }
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            TermsConditionsLabels.getLabel(getCurrentLanguage(), 'title'),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 5),
          Text(
            TermsConditionsLabels.getLabel(getCurrentLanguage(), 'text'),
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white70),
          ),

        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.teal.shade700),
            ),
            SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
