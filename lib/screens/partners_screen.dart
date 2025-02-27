import 'package:donation_app_v1/const_values/title_values.dart';
import 'package:donation_app_v1/enums/currency_enum.dart';
import 'package:donation_app_v1/enums/drawer_enum.dart';
import 'package:donation_app_v1/models/drawer_model.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final supabase = Supabase.instance.client;

class PartnersPage extends StatefulWidget {
  const PartnersPage({super.key});

  @override
  State<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage> {
  Future<List<Map<String, dynamic>>> getSponsors() async {
    final response = await supabase.from('sponsors').select('*').order('category', ascending: true);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider= Provider.of<ProfileProvider>(context,listen: false);

    return Scaffold(
      drawer: DonationAppDrawer(drawerIndex: DrawerItem.partners.getInt(),),
      appBar: AppBar(
        title: Text(PageTitles.getTitle(profileProvider.profile!.settings.language, 'partners_page_title')),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: getSponsors(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sponsorsByCategory = _groupByCategory(snapshot.data!);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sponsorsByCategory.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: _getCategoryColor(entry.key),
                          ),
                        ),
                      ),

                      if (entry.value.isEmpty) // Show message if no sponsors
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "No sponsors in this category",
                            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey[700]),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: entry.value.length,
                          itemBuilder: (context, index) {
                            final sponsor = entry.value[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SponsorDetailPage(sponsor: sponsor),
                                  ),
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        sponsor["logo_url"],
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    Text(
                                      sponsor["name"],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 25),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByCategory(List<Map<String, dynamic>> sponsors) {
    final grouped = {
      "🏅 Gold Sponsors": <Map<String, dynamic>>[],
      "🥉 Bronze Sponsors": <Map<String, dynamic>>[],
      "🥈 Silver Sponsors": <Map<String, dynamic>>[],
      "🤝 Partners": <Map<String, dynamic>>[],
      "💯 100 X 100 Sponsors": <Map<String, dynamic>>[],
    };

    for (var sponsor in sponsors) {
      String category = _getCategoryName(sponsor["category"]);
      grouped[category]?.add(sponsor);
    }

    return grouped;
  }

  String _getCategoryName(String category) {
    switch (category.toLowerCase()) {
      case "gold":
        return "🏅 Gold Sponsors";
      case "silver":
        return "🥈 Silver Sponsors";
      case "bronze":
        return "🥉 Bronze Sponsors";
      case "100 x 100":
        return "💯 100 X 100 Sponsors";
      default:
        return "🤝 Partners";
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "🏅 Gold Sponsors":
        return Colors.amber[800]!;
      case "🥈 Silver Sponsors":
        return Colors.grey[600]!;
      case "🥉 Bronze Sponsors":
        return Colors.brown[600]!;
      case "💯 100 X 100 Sponsors":
        return Colors.blue[800]!;
      default:
        return Colors.teal;
    }
  }
}

// ==========================
// SPONSOR DETAIL PAGE
// ==========================


class SponsorDetailPage extends StatelessWidget {
  final Map<String, dynamic> sponsor;

  const SponsorDetailPage({Key? key, required this.sponsor}) : super(key: key);

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
  String formatAmount(int amount,BuildContext context) {
    final profileProvider= Provider.of<ProfileProvider>(context,listen: false);
    final currentCurrency = Currency.values.firstWhere((element) => element.code == profileProvider.profile!.settings.currency);
    final currencyFormat = currentCurrency.format(amount.toDouble());
    if (amount >= 1000000) {
      double result = amount / 1000000;
      return result == result.toInt().toDouble()
          ? '${currentCurrency.symbol} ${currentCurrency.convert(result.toDouble(),currentCurrency)}M'
          : '${currentCurrency.symbol} ${currentCurrency.convert(result.toDouble(),currentCurrency).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      double result = amount / 1000;
      return result == result.toInt().toDouble()
          ? '${currentCurrency.symbol} ${currentCurrency.convert(result.toDouble(),currentCurrency)}k'
          : '${currentCurrency.symbol} ${currentCurrency.convert(result.toDouble(),currentCurrency).toStringAsFixed(1)}k';
    } else {
      return  "${currentCurrency.symbol} ${currentCurrency.convert(amount.toDouble(),currentCurrency)}";
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sponsor["name"]),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Sponsor Information"),
                _buildCenteredCard(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          sponsor["logo_url"],
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        sponsor["name"],
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),

                _buildSectionHeader("Sponsorship Details"),
                _buildDetailRow(Icons.monetization_on, "Contribution", "${formatAmount(sponsor["contribution_amount"].toInt(), context)}"),
                _buildDetailRow(Icons.emoji_events, "Sponsorship Type", sponsor["sponsorship_type"]),
                _buildDetailRow(Icons.timer, "Duration", sponsor["sponsorship_duration"]),
                _buildDetailRow(Icons.person, "Representative", sponsor["representative_name"]),

                _buildSectionHeader("Company Details"),
                _buildDetailRow(Icons.business, "Industry", sponsor["industry"]),
                _buildDetailRow(Icons.location_on, "Location", sponsor["location"]),

                _buildSectionHeader("About Sponsor"),
                _buildDescriptionCard(sponsor["description"]),

                if (sponsor["history"] != null) ...[
                  _buildSectionHeader("History"),
                  _buildDescriptionCard(sponsor["history"]),
                ],

                _buildSectionHeader("Contact Information"),
                if (sponsor["contact_email"] != null)
                  _buildDetailRow(Icons.email, "Email", sponsor["contact_email"]),

                _buildSectionHeader("More Information"),
                ElevatedButton.icon(
                  onPressed: () => _launchURL(sponsor["website_url"]),
                  icon: const Icon(Icons.language),
                  label: const Text("Visit Website"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                ),
                const SizedBox(height: 20),

                if (sponsor["social_media"] != null)
                  Wrap(
                    spacing: 10,
                    children: (sponsor["social_media"] as List<dynamic>).map((social) {
                      return IconButton(
                        icon: _getSocialMediaIcon(social["platform"]),
                        onPressed: () => _launchURL(social["url"]),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredCard({required Widget child}) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildDescriptionCard(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Icon _getSocialMediaIcon(String platform) {
    switch (platform.toLowerCase()) {
      case "linkedin":
        return const Icon(Icons.work, color: Colors.blue);
      case "twitter":
        return const Icon(Icons.chat, color: Colors.lightBlue);
      case "facebook":
        return const Icon(Icons.facebook, color: Colors.blueAccent);
      case "instagram":
        return const Icon(Icons.camera_alt, color: Colors.pink);
      default:
        return const Icon(Icons.link, color: Colors.black);
    }
  }
}
