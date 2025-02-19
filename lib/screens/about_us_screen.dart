import 'package:donation_app_v1/models/drawer_model.dart';
import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DonationAppDrawer(),
      appBar: AppBar(
        title: const Text('Σχετικά με Εμάς'),
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
              // Header with Image and Overlay
              Container(
                height: 250,
                child: Stack(
                  children: [
                    Container(
                      height: 250,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/panther_racing_team.jpg'), // Replace with your image
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

              // Mission Section
              _buildSection(
                title: 'Η Αποστολή μας',
                content:
                'Στο Panther Racing Team AUTH, συνδυάζουμε την ακαδημαϊκή γνώση με την πρακτική εμπειρία για να σχεδιάσουμε, να κατασκευάσουμε και να συναρμολογήσουμε μοτοσικλέτες υψηλών επιδόσεων από την αρχή. Στόχος μας είναι να διευρύνουμε τα όρια της καινοτομίας και να εκπροσωπήσουμε το Αριστοτέλειο Πανεπιστήμιο Θεσσαλονίκης σε παγκόσμιο επίπεδο.',
                icon: Icons.lightbulb_outline,
              ),
              const Divider(),

              // Journey Section
              _buildSection(
                title: 'Το Ταξίδι',
                content:
                'Από την πρώτη ιδέα έως την κατασκευή κάθε εξαρτήματος, το ταξίδι μας αντικατοπτρίζει την ομαδικότητα, τη δημιουργικότητα και την επιμονή. Κάθε μοτοσικλέτα που κατασκευάζουμε είναι μια απόδειξη της αφοσίωσης και του πάθους μας για τον μηχανοκίνητο αθλητισμό.',
                icon: Icons.emoji_events_outlined,
              ),
              const Divider(),

              // Motostudent Section
              _buildSection(
                title: 'Motostudent - Μια Παγκόσμια Σκηνή',
                content:
                'Το Motostudent είναι ένας διεθνής διαγωνισμός πανεπιστημιακού επιπέδου που πραγματοποιείται στην εμβληματική πίστα της Αραγονίας στην Ισπανία. Αυτή η πλατφόρμα μας δίνει την ευκαιρία να δοκιμάσουμε τις μηχανικές μας δεξιότητες και την καινοτομία μας ενάντια στις καλύτερες ομάδες παγκοσμίως.',
                icon: Icons.flag_outlined,
              ),
              const Divider(),

              // Support Section
              _buildSection(
                title: 'Γιατί Χρειαζόμαστε τη Στήριξή σας',
                content:
                'Η κατασκευή μιας μοτοσικλέτας έτοιμης για αγώνες απαιτεί σημαντικούς πόρους. Η υποστήριξή σας μας βοηθά να αποκτήσουμε υλικά, να βελτιώσουμε το σχέδιό μας και να καλύψουμε τα έξοδα ταξιδιού για τον διαγωνισμό. Μαζί, μπορούμε να εμπνεύσουμε την επόμενη γενιά μηχανικών.',
                icon: Icons.volunteer_activism,
              ),
              const SizedBox(height: 20),

              // Call to Action Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    _launchInAppWithBrowserOptions(Uri.parse('https://instagram.com/panther_racing'));
                  },

                  icon: const Icon(Icons.favorite, color: Colors.white),
                  label: const Text(
                    'Στηρίξτε μας',
                    style: TextStyle(fontSize: 16,color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 15.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Section Widget
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
          // Icon
          Icon(icon, size: 30, color: Colors.teal),
          const SizedBox(width: 16),
          // Text Content
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
