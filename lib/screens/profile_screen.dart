import 'package:donation_app_v1/const_values/profile_page_values.dart';
import 'package:donation_app_v1/const_values/title_values.dart';
import 'package:donation_app_v1/enums/currency_enum.dart';
import 'package:donation_app_v1/enums/drawer_enum.dart';
import 'package:donation_app_v1/models/drawer_model.dart';
import 'package:donation_app_v1/enums/card_type_enum.dart';
import 'package:donation_app_v1/models/card_model.dart';
import 'package:donation_app_v1/models/settings_model.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:donation_app_v1/widgets/balance_widget.dart';
import 'package:donation_app_v1/widgets/profile_avatar_widget.dart';
import 'package:donation_app_v1/widgets/wallet_widget.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client

class ProfilePage extends StatefulWidget {
  bool isTopDonator;

  ProfilePage({required this.isTopDonator});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Sample data for user profile and donations
  List<Map<String, dynamic>> donationHistory =[];
  Map<String,dynamic> donationsByUsername={};
  int wallet=0;

  final List<String> favoriteCauses = ["Education", "Health", "Environment"];
  int? selectedPredefinedAmount;
  TextEditingController _amountController = TextEditingController();
  bool isLoading=false;

  @override
  void initState(){
    super.initState();
    _fetchDonations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
    // print(donationsByUsername);
  }



  Map<String, dynamic> aggregateDonationByUsername(
      List<Map<String, dynamic>> donations) {
    String username=_supabaseClient.auth.currentUser!.userMetadata!['username'];
    // Initialize variables to store total amount and donation list
    int totalAmount = 0;
    List<Map<String, dynamic>> userDonations = [];

    for (var donation in donations) {
      totalAmount += donation['amount'] as int;
      userDonations.add(donation);
    }
    // Create the aggregated result
    return {
      'username': username,
      'totalAmount': totalAmount,
      'donations': userDonations,
    };
  }
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }




  Future<void> _fetchDonations() async {
    try {
      isLoading=true;
      final response = await _supabaseClient
          .from('donations') // Replace 'donations' with your table name
          .select()
          .eq('username', _supabaseClient.auth.currentUser!.userMetadata!['username'])
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        setState(() {
          donationHistory = List<Map<String, dynamic>>.from(response);
          // print(donationHistory);
          donationsByUsername =aggregateDonationByUsername(donationHistory);
        });
        isLoading=false;

      } else {
        _showMessage('No donations found.');
        isLoading=false;

      }

    } catch (e) {
      print('An unexpected error occurred: $e');
      _showMessage('Please Retry.');

      isLoading=false;
    }finally {
      isLoading=false;
      setState(() {

      });
    }
  }
  String formatAmount(int amount) {
    final profileProvider= Provider.of<ProfileProvider>(context,listen: false);
    final currentCurrency = Currency.values.firstWhere((element) => element.code == profileProvider.profile!.settings.currency);
    if (amount >= 1000000) {
      double result = amount / 1000000;
      return result == result.toInt().toDouble()
          ? '${currentCurrency.symbol} ${result.toInt()}M'
          : '${currentCurrency.symbol} ${result.toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      double result = amount / 1000;
      return result == result.toInt().toDouble()
          ? '${currentCurrency.symbol} ${result.toInt()}k'
          : '${currentCurrency.symbol} ${result.toStringAsFixed(1)}k';
    } else {
      return  "${currentCurrency.symbol} ${currentCurrency.convert(amount.toDouble(),currentCurrency)}";
    }
  }
  void _addDonation() {
    final amount = selectedPredefinedAmount ?? int.tryParse(_amountController.text.trim());
    if (amount != null) {
      // Add donation logic here, for example:
      // _insertDonation(amount);
      print("Donation of \$${amount} added.");
    }
  }
  String formatAmountWithBullets(int amount, BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final currentCurrency = Currency.values.firstWhere(
          (element) => element.code == profileProvider.profile!.settings.currency,
    );

    // Convert amount to currency format
    double convertedAmount = currentCurrency.convert(amount.toDouble(), currentCurrency);
    final currencyFormat = "${currentCurrency.symbol} ${currentCurrency.convert(amount.toDouble(),currentCurrency).toStringAsFixed(2)}";

    // Replace commas with dots for bullet-style formatting
    return currencyFormat.replaceAll(',', '.');
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
    ProfileProvider profileProvider=Provider.of<ProfileProvider>(context,listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(PageTitles.getTitle(getCurrentLanguage(), 'profile_page_title')),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      drawer: DonationAppDrawer(drawerIndex: DrawerItem.profile.index,),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.tealAccent.shade400, Colors.teal.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child:  isLoading ? Center(child: CircularProgressIndicator()) : Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 10,vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 12),
                    child: Row(
                      children: [
                        // Circular Profile Avatar
                        ProfileAvatar(),
                        const SizedBox(width: 16),

                        // User Info Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _supabaseClient.auth.currentUser!.userMetadata!['username'] ?? "User",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if(widget.isTopDonator)
                                Row(
                                  children:  [
                                    Icon(Icons.star, color: Colors.amber, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      ProfileLabels.getLabel(getCurrentLanguage(), 'top_donors_title_value'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              Container(

                                child: Column(
                                  children: [
                                    Text(
                                      ProfileLabels.getLabel(getCurrentLanguage(), 'total_donations_value'),
                                      style:  TextStyle(
                                          fontSize: 16,
                                          color: Colors.teal.shade700,
                                          fontWeight: FontWeight.bold
                                      ),
                                    ),
                                    Text(
                                      "${formatAmountWithBullets(donationsByUsername['totalAmount'] ?? 0,context)}",
                                      style:  TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        // Trophy Icon
                        if(widget.isTopDonator)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.withOpacity(0.2),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.emoji_events, color: Colors.amber, size: 35),
                          ),
                      ],
                    ),
                  ),
                ),



                Divider(height: 32, color: Colors.grey[300]),

                WalletWidget(cards: profileProvider.profile!.paymentCards),
                Divider(height: 32, color: Colors.grey[300]),
                // Donation History
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding:  EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        _buildSectionHeader(ProfileLabels.getLabel(getCurrentLanguage(), 'donation_history_title_value')),
                        SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildDonationHistory(),
                        ),

                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                )
                // Donation Goal
                // _buildSectionHeader("Donation Goal"),
                // SizedBox(height: 16),
                // _buildDonationGoal(),
                //
                // Divider(height: 32, color: Colors.grey[300]),
                //
                // // Favorite Causes
                // _buildSectionHeader("Favorite Causes"),
                // SizedBox(height: 16),
                // _buildFavoriteCauses(),
                //
                // Divider(height: 32, color: Colors.grey[300]),
                //
                // // Add Donation Section
                // _buildSectionHeader("Add Donation"),
                // SizedBox(height: 16),
                // _buildPredefinedAmountButtons(),
                // SizedBox(height: 16),
                // _buildCustomAmountField(),
                // SizedBox(height: 16),

                // Action Buttons
                // _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
    );
  }
  String calculateTimeDifference(String createdAt) {
    try {
      // Ensure the date is parsed correctly
      final createdTime = DateTime.parse(createdAt); // Parse and convert to UTC
      // print('Created Time: $createdTime');
      final currentTime = DateTime.now(); // Get the current time
      // print('Current Time: $currentTime');

      // Calculate the difference between the two times
      int years = currentTime.year - createdTime.year;
      int months = currentTime.month - createdTime.month;
      int days = currentTime.day - createdTime.day;
      int hours = currentTime.hour - createdTime.hour;
      int minutes = currentTime.minute - createdTime.minute;
      int seconds = currentTime.second - createdTime.second;

      // Adjust for negative differences (e.g., if months, days, etc., are negative)
      if (seconds < 0) {
        seconds += 60;
        minutes -= 1;
      }
      if (minutes < 0) {
        minutes += 60;
        hours -= 1;
      }
      if (hours < 0) {
        hours += 24;
        days -= 1;
      }
      if (days < 0) {
        // If days are negative, handle month difference
        final previousMonth = DateTime(currentTime.year, currentTime.month - 1, createdTime.day);
        days = currentTime.difference(previousMonth).inDays;
        months -= 1;
      }
      if (months < 0) {
        months += 12;
        years -= 1;
      }

      // Handle future dates where difference might be negative
      if (years < 0 || months < 0 || days < 0) {
        return 'In the future'; // Or handle it in some other way
      }

      // Format the time difference in a human-readable way
      if (years > 0) {
        return '$years year${years > 1 ? 's' : ''} ago';
      } else if (months > 0) {
        return '$months month${months > 1 ? 's' : ''} ago';
      } else if (days > 0) {
        return '$days day${days > 1 ? 's' : ''} ago';
      } else if (hours > 0) {
        return '$hours hour${hours > 1 ? 's' : ''} ago';
      } else if (minutes > 0) {
        return '$minutes minute${minutes > 1 ? 's' : ''} ago';
      }else {
        return 'Just now';
      }
    } catch (e) {
      // Handle any errors in parsing or time calculations
      print('Error in parsing date: $e');
      return 'Invalid date';
    }
  }





  // Donation History
  Widget _buildDonationHistory() {
    if (donationHistory.isNotEmpty) {
      return Column(
        children: donationHistory.map((donation) {
          // Optionally convert the payment_method JSON into a PaymentCard instance
          PaymentCard? paymentCard;
          if (donation['payment_method'] != null) {
            try {
              paymentCard = PaymentCard.fromJson(
                Map<String, dynamic>.from(donation['payment_method']),
              );
            } catch (e) {
              // Handle any conversion errors if needed.
            }
          }

          return Card(
            color: Colors.teal.shade400,
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 5,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Donation Amount and Description
                  Row(
                    children: [
                      const Icon(Icons.monetization_on,
                          color: Colors.white, size: 30),
                      const SizedBox(width: 8),
                      Text(
                        "${formatAmountWithBullets(donation['amount'],context)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        calculateTimeDifference(donation['created_at']!),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    donation['description'] != ''
                        ? donation['description']
                        : ProfileLabels.getLabel(getCurrentLanguage(), 'no_description_value'),
                    style: donation['description'] != ''
                        ? const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    )
                        : const TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Divider for visual separation
                  Divider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                  ),
                  // Payment Card Info (if available)
                  if (paymentCard != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        paymentCard.cardType.getIcon(color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          "**** **** **** ${paymentCard.cardNumber.substring(paymentCard.cardNumber.length - 4)}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Optional category or extra info (if available)
                  if (donation['category'] != null)
                    Row(
                      children: [
                        const Icon(Icons.category, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          donation['category'] ?? ProfileLabels.getLabel(getCurrentLanguage(), 'no_category_value'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Container(
        height: 200,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 48,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 16),
              Text(
                ProfileLabels.getLabel(getCurrentLanguage(), 'no_donations_value'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Donation Goal Section
  Widget _buildDonationGoal() {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Goal: \$500 this year", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            LinearProgressIndicator(value: 0.6, color: Colors.teal),
            SizedBox(height: 8),
            Text("60% reached", style: TextStyle(fontSize: 14, color: Colors.teal)),
          ],
        ),
      ),
    );
  }

  // Favorite Causes Section
  Widget _buildFavoriteCauses() {
    return Wrap(
      spacing: 8.0,
      children: favoriteCauses.map((cause) {
        return Chip(
          label: Text(cause),
          backgroundColor: Colors.teal[100],
        );
      }).toList(),
    );
  }

  // Predefined Amount Buttons
  Widget _buildPredefinedAmountButtons() {
    return Wrap(
      spacing: 8.0,
      children: [100, 500, 1000, 10000, 100000].map((amount) {
        return ChoiceChip(
          label: Text("\$$amount"),
          selected: selectedPredefinedAmount == amount,
          onSelected: (selected) {
            setState(() {
              selectedPredefinedAmount = selected ? amount : null;
              _amountController.clear(); // Clear custom amount
            });
          },
        );
      }).toList(),
    );
  }

  // Custom Amount Field
  Widget _buildCustomAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Custom Amount',
        hintText: 'Enter donation amount',
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Action Buttons
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close the profile page
          },
          child: Text("Cancel", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: _addDonation,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: Text("Add", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}





