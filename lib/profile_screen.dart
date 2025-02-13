import 'package:donation_app_v1/drawer_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  Map<String,dynamic> profile={};
  Map<String,dynamic> donationsByUsername={};

  final List<String> favoriteCauses = ["Education", "Health", "Environment"];
  int? selectedPredefinedAmount;
  TextEditingController _amountController = TextEditingController();
  bool isLoading=false;

  @override
  void initState(){
    super.initState();
    _fetchDonations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
    print(donationsByUsername);
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

  Future<void> _fetchProfile() async {
    try {
      isLoading=true;
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('username', _supabaseClient.auth.currentUser!.userMetadata!['username']);

      if (response.isNotEmpty) {
        setState(() {
          profile = response.first;
          // Remove the unnecessary print statement if not needed
          // print(profile);
        });
      } else {
        _showMessage('No profile found for the current user.');
      }

    } catch (e) {
      print('Error fetching profile: $e');
      _showMessage('An error occurred while fetching your profile. Please try again later.');
    }
    finally{
      setState(() {

        isLoading=false;
      });
    }
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
          print(donationHistory);
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

  void _addDonation() {
    final amount = selectedPredefinedAmount ?? int.tryParse(_amountController.text.trim());
    if (amount != null) {
      // Add donation logic here, for example:
      // _insertDonation(amount);
      print("Donation of \$${amount} added.");
    }
  }
  String formatAmountWithBullets(int amount) {
    // Use NumberFormat from the intl package
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount).replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.teal,
      ),
      drawer: DonationAppDrawer(),
      body: isLoading ? Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Row(
                children: [
                  // Circular Profile Avatar
                  CircleAvatar(
                    radius: 42  ,
                    backgroundColor: Colors.teal,
                    child: Text(
                      (_supabaseClient.auth.currentUser!.userMetadata!['username'] ?? "User")[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
                            children: const [
                              Icon(Icons.star, color: Colors.amber, size: 18),
                              SizedBox(width: 4),
                              Text(
                                "Top Donor",
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
                                "Total Donations: ",
                                style:  TextStyle(
                                    fontSize: 16,
                                    color: Colors.teal.shade700,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                              Text(
                                "${formatAmountWithBullets(donationsByUsername['totalAmount'] ?? 0)} \$",
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

              Text(
                "${formatAmountWithBullets(profile['wallet'])} \$",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Divider(height: 32, color: Colors.grey[300]),

              // Donation History
              _buildSectionHeader("Donation History"),
              SizedBox(height: 16),
              _buildDonationHistory(),

              Divider(height: 32, color: Colors.grey[300]),
              WalletWidget()
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
      print('Created Time: $createdTime');
      final currentTime = DateTime.now(); // Get the current time
      print('Current Time: $currentTime');

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


    if(donationHistory.isNotEmpty){
      return Column(
        children: donationHistory.map((donation) {
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Donation Amount and Description
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.teal, size: 30),
                      SizedBox(width: 8),
                      Text(
                        "\$${formatAmountWithBullets(donation['amount'])}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      Spacer(),
                      Text(
                        calculateTimeDifference(donation['created_at']!),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Description
                  Text(
                    donation['description'] !='' ? donation['description'] : 'No description',
                    style: donation['description'] !='' ? TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ) : TextStyle(
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
                  SizedBox(height: 8),
                  // Optional category or extra info (if you have it)
                  donation['category'] != null
                      ? Row(
                    children: [
                      Icon(Icons.category, color: Colors.teal, size: 20),
                      SizedBox(width: 8),
                      Text(
                        donation['category'] ?? 'No category',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.teal.shade600,
                        ),
                      ),
                    ],
                  )
                      : SizedBox.shrink(), // If there's no category, don't show
                ],
              ),
            ),
          );
        }).toList(),
      );
    }else{
      return Container(
        height: 200,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20)
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 48,
                color: Colors.grey.shade600,
              ),
              SizedBox(height: 16),
              Text(
                "No Donations",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        )
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



class WalletWidget extends StatefulWidget {
  @override
  _WalletWidgetState createState() => _WalletWidgetState();
}

class _WalletWidgetState extends State<WalletWidget> {
  String cardNumber = '**** **** **** 1234';
  String expirationDate = '01/25';
  String balance = '1000.00';

  @override
  void initState() {
    super.initState();
    _loadCardDetails();
  }

  Future<void> _loadCardDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cardNumber = prefs.getString('cardNumber') ?? '**** **** **** 1234';
      expirationDate = prefs.getString('expirationDate') ?? '01/25';
      balance = prefs.getString('balance') ?? '1000.00';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Balance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$$balance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card Details Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),

              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cardNumber),
                      Text(expirationDate),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}