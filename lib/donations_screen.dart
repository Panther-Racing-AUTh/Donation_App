import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:donation_app_v1/donation_card_screen.dart';
import 'package:donation_app_v1/drawer_model.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

import 'package:charts_flutter/flutter.dart' as charts;




final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client

class DonationsPage extends StatefulWidget {
  @override
  _DonationsPageState createState() => _DonationsPageState();
}

class _DonationsPageState extends State<DonationsPage> {
  final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client
  late RealtimeChannel channelDonation;
  late RealtimeChannel channelDonationItem;

  List<Map<String, dynamic>> _donations = [];
  List<Map<String,dynamic>>  _donators=[];
  List<Map<String, dynamic>> _donationItems = [];
  List<String> _donation_item_images=[];
  String topDonatorUsername='';

  bool _isOnline=true;
  bool _isLoading = false;
  bool _isCarouselCardLoading=false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  late Timer _timerConnectionCheck;

  @override
  void initState() {
    super.initState();
    _timerConnectionCheck=Timer.periodic(Duration(seconds: 5), (timer) {
      _connectionCheck();
    },);
    _fetchDonations();
    _fetchDonationItems();
    _listenToDonationChanges();
    _listenToDonationItemChanges();
    fetchFileUrls(bucketName: 'myBucket',path: 'image/');
  }

  @override
  void dispose() {
    _timerConnectionCheck.cancel();
    channelDonation.unsubscribe();
    channelDonationItem.unsubscribe();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
  /// Function to check Wi-Fi connectivity
  Future<bool> isConnectedToWiFi() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.mobile);
    } catch (e) {
      print('Error checking internet connectivity: $e');
      return false;
    }
  }
  Future<void> _connectionCheck() async {
    bool isConnected = await isConnectedToWiFi();
    setState(() {
      _isOnline = isConnected;
    });

    setState(() {

    });
  }


  /// Fetch existing donations from the database
  Future<void> _fetchDonations() async {
    try {
      final response = await _supabaseClient
          .from('donations') // Replace 'donations' with your table name
          .select()
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        setState(() {
          _donations = List<Map<String, dynamic>>.from(response);
          _donators= organizeDonationsByName(_donators,_donations);
          findTopDonatorUsername(_donators);
        });
      } else {
        _showMessage('No donations found.');
      }
    } catch (e) {
      _showMessage('An unexpected error occurred: $e');
    }
  }
  Future<void> _fetchDonationItems() async {

    try {
      _isCarouselCardLoading=true;
      final response = await _supabaseClient
          .from('donation_items') // Replace 'donations' with your table name
          .select()
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        setState(() {
          _donationItems = List<Map<String, dynamic>>.from(response);
        });
      } else {
        _showMessage('No donation Items found.');
      }

      _isCarouselCardLoading=false;
    } catch (e) {
      _isCarouselCardLoading=false;
      _showMessage('An unexpected error occurred: $e');
    }
  }
  Future<void> fetchFileUrls({required String bucketName,String path=''}) async{
    final List<FileObject> objects = await _supabaseClient
        .storage
        .from(bucketName)
        .list(path: path);
    _donation_item_images= objects.map((file) {
      return _supabaseClient.storage.from(bucketName).getPublicUrl('${path}${file.name}');
    }).toList();
    print("check : ${_donation_item_images}");

  }
  Future<void> updateDonationItemAmount({required String itemId,required int newAmount}) async {
    try {
      final supabase = Supabase.instance.client;

      // Perform the update
      final response = await supabase
          .from('donation_items') // Name of your table in Supabase
          .update({'amount': newAmount}) // The field to update
          .eq('id', itemId); // Filter to match the specific item by its ID



      print('Donation item updated successfully!');
    } catch (e) {
      print('Error updating donation item: $e');
    }
  }
  Future<void> uploadImageAndInsertDonationItem({required String title,String? description,int amount = 0,required String imagePath,bool isActive = true,DateTime? timer,}) async {
    try {
      String fileName='';
      File file;
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        file = File(result.files.single.path!);
      } else {
        throw Exception('Image upload failed: ${result}');
        // User canceled the picker
      }

      // Upload the image to Supabase storage
      final uploadResponse = await _supabaseClient.storage
          .from('myBucket') // Replace with your bucket name
          .upload('images/${result.files.single.name}', file);

      // Check for errors in the upload process
      if (uploadResponse != null) {
        throw Exception('Image upload failed: ${uploadResponse}');
      }

      // Get the public URL of the uploaded image
      final imageUrl = _supabaseClient.storage
          .from('myBucket')
          .getPublicUrl('images/$fileName');

      // Insert the donation item with the image URL
      final response = await _supabaseClient.from('donation_items').insert({
        'title': title,
        'amount': amount,
        'image_url': imageUrl,
        'is_active': isActive,
        'timer': timer?.toIso8601String(),
      }).select();

      // Check for errors in the insert process
      if (response.isEmpty) {
        throw Exception('Failed to insert donation item: ${response}');
      }

      // Return the inserted record
    } catch (e) {
      print('Error: $e');
    }
  }
  Future<void> _refreshData() async {
    // Simulate a network call or refresh logic
    await Future.delayed(Duration(seconds: 2));

    // Check internet connection or reload data
    bool online = await isConnectedToWiFi(); // Replace with actual internet check logic


  }


  /// Insert a new donation into the database
  Future<void> _insertDonation({int amount=0,required int category,String description=''}) async {
    setState(() {
      _isLoading = true;
    });

    final title = _titleController.text.trim();
    // final amount = double.tryParse(_amountController.text.trim());

    final profileId = _supabaseClient.auth.currentUser!.id;


    if (amount <= 0) {
      _showMessage('Please enter valid donation details.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await _supabaseClient.from('donations').insert({
        "username" : _supabaseClient.auth.currentUser!.userMetadata!['username'] ?? "User",
        "email" : _supabaseClient.auth.currentUser!.email,
        "amount": amount,
        "created_at": DateTime.now().toIso8601String(),
        "donation_item_id" : category,
        'description' : description,
        "profile_id": profileId,
      });

      _titleController.clear();
      _amountController.clear();
    } catch (e) {
      _showMessage('An unexpected error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Listen to real-time changes in donations
  void _listenToDonationItemChanges() {
    channelDonationItem = _supabaseClient
        .channel('public:donation_items') // Replace 'public:donation_items' with your schema and table
    // Listen for new donation items
        .onPostgresChanges(
      table: 'donation_items',
      event: PostgresChangeEvent.insert,
      callback: (payload) {
        final newRecord = payload.newRecord;

        if (newRecord.isNotEmpty) {
          setState(() {
            // Check if the item already exists in the list
            final exists = _donationItems.any((item) => item['id'] == newRecord['id']);

            if (!exists) {
              _donationItems.insert(0, newRecord); // Add new donation item to the top
            }
          });
        }
      },
    )
    // Listen for deleted donation items
        .onPostgresChanges(
      table: 'donation_items',
      event: PostgresChangeEvent.delete,
      callback: (payload) {
        final deletedRecord = payload.oldRecord;

        if (deletedRecord.isNotEmpty) {
          setState(() {
            // Remove the item with the matching id from the list
            _donationItems.removeWhere((item) => item['id'] == deletedRecord['id']);
          });
        }
      },
    )
    // Listen for updated donation items
        .onPostgresChanges(
      table: 'donation_items',
      event: PostgresChangeEvent.update,
      callback: (payload) {
        final updatedRecord = payload.newRecord;

        if (updatedRecord.isNotEmpty) {
          setState(() {
            // Find the index of the existing item in the list
            final index = _donationItems.indexWhere((item) => item['id'] == updatedRecord['id']);

            if (index != -1) {
              // Update the existing item
              _donationItems[index] = updatedRecord;
            }
          });
        }
      },
    )
        .subscribe();
  }
  void _listenToDonationChanges() {
    channelDonation = _supabaseClient
        .channel('public:donations') // Replace with your schema and table name
        .onPostgresChanges(
      table: 'donations',
      event: PostgresChangeEvent.insert,
      callback: (payload) {
        final newRecord = payload.newRecord;
        setState(() {
          // Add new donation to the top
          _donations.insert(0, newRecord);

          // Reorganize donators
          List<Map<String, dynamic>> tempDonators = List.castFrom(_donators);
          _donators.clear();
          _donators = organizeDonationsByName(tempDonators, _donations);
          findTopDonatorUsername(_donators);

          List<Map<String, dynamic>> tempDonationEvents= organizeDonationsByEvent(_donations);
          for(var tempDonationItem in tempDonationEvents){
            updateDonationItemAmount(itemId: tempDonationItem['donation_item_id'], newAmount: tempDonationItem['amount']);
          }
        });
      },
    )
        .onPostgresChanges(
      table: 'donations',
      event: PostgresChangeEvent.update,
      callback: (payload) {
        final updatedRecord = payload.newRecord;
        setState(() {
          // Find the donation to update
          final index = _donations.indexWhere((donation) =>
          donation['id'] == updatedRecord['id']); // Assuming `id` is the unique key
          if (index != -1) {
            // Update the donation
            _donations[index] = updatedRecord;
          }

          // Reorganize donators
          List<Map<String, dynamic>> temp = List.castFrom(_donators);
          _donators.clear();
          _donators = organizeDonationsByName(temp, _donations);
          findTopDonatorUsername(_donators);




        });
      },
    )
        .onPostgresChanges(
      table: 'donations',
      event: PostgresChangeEvent.delete,
      callback: (payload) {
        final deletedRecord = payload.oldRecord;
        final newRecord =payload.newRecord;
        setState(() {
          print(newRecord);
          // Remove the donation
          _donations.removeWhere(
                  (donation) => donation['id'] == deletedRecord['id']);
          print("Donations : ${_donations}");
          // Reorganize donators
          List<Map<String, dynamic>> temp = List.castFrom(_donators);
          _donators.clear();
          _donators = organizeDonationsByName(temp, _donations);


          List<Map<String, dynamic>> tempDonationEvents= organizeDonationsByEvent(_donations);
          print("Niaou: ${tempDonationEvents}");
          if(tempDonationEvents.isEmpty){
            for(var donationItem in _donationItems){
              updateDonationItemAmount(itemId: donationItem['id'], newAmount: 0);
            }
          }else{
            for(var tempDonationItem in tempDonationEvents){
              print('${tempDonationItem['amount']}');
              updateDonationItemAmount(itemId: tempDonationItem['donation_item_id'], newAmount: tempDonationItem['amount']);
            }
          }
        });
      },
    ).subscribe();
  }





  List<Map<String, dynamic>> calculateTotalAmountByItem(List<Map<String, dynamic>> donations) {
    try {
      // Create a map to store totals for each donation item
      final Map<String, int> donationTotals = {};

      // Aggregate amounts by donation item
      for (var donation in donations) {
        final String item = donation['donation_item_id'] as String;
        final int amount = donation['amount'] as int;

        if (donationTotals.containsKey(item)) {
          donationTotals[item] = donationTotals[item]! + amount;
        } else {
          donationTotals[item] = amount;
        }
      }

      // Convert the map to a list of maps
      return donationTotals.entries.map((entry) {
        return {
          'donation_item_id': entry.key,
          'amount': entry.value,
        };
      }).toList();
    } catch (e) {
      print('Error calculating total amount by donation item: $e');
      return [];
    }
  }
  int calculateTotalDonationAmount(List<Map<String, dynamic>> donations) {
    try {
      // Calculate the total amount by summing the 'amount' field
      return donations.fold<int>(
        0, // Initial value of the total
            (sum, item) => sum + (item['amount'] as int),
      );
    } catch (e) {
      print('Error calculating total donation amount: $e');
      return 0; // Return 0 if an error occurs
    }
  }
  List<Map<String, dynamic>> organizeDonationsByEvent(List<Map<String, dynamic>> donations) {
    try {
      // Organize donations by name
      final Map<String, int> organizedDonations = {};
      for(var donationItem in _donationItems){
        final String donation_item_id = donationItem['id'].toString();
        organizedDonations[donation_item_id] = 0;
      }

      for (var donation in donations) {
        final String donation_item_id = donation['donation_item_id'].toString();
        final int amount = donation['amount'] ;

        if (organizedDonations.containsKey(donation_item_id)) {
          // Add to the total amount if the name already exists
          organizedDonations[donation_item_id] = organizedDonations[donation_item_id]! + amount;
        } else {
          // Initialize with the current amount
          organizedDonations[donation_item_id] = amount;
        }
      }

      // Convert the map to a list
      final List<Map<String, dynamic>> donationList = organizedDonations.entries.map((entry) {
        print(entry);
        return {
          'donation_item_id': entry.key,
          'amount': entry.value,
        };
      }).toList();

      return donationList;
    } catch (e) {
      print('Error organizing 1donations: $e');
      return [];
    }
  }
  List<Map<String, dynamic>> organizeDonationsByName(List<Map<String,dynamic>> donators,List<Map<String, dynamic>> donations) {
    try {
      // Organize donations by name
      final Map<String, int> organizedDonations = {};
      if(_donators.isNotEmpty){
        for (var donator in donators) {
          final String name = donator['username'] as String;
          final int amount = donator['amount'] as int;
          organizedDonations[name] = amount;
          print(organizedDonations);
        }
      }

      for (var donation in donations) {
        final String name = donation['username'] as String;
        final int amount = donation['amount'] as int;

        if (organizedDonations.containsKey(name)) {
          // Add to the total amount if the name already exists
          organizedDonations[name] = organizedDonations[name]! + amount;
        } else {
          // Initialize with the current amount
          organizedDonations[name] = amount;
        }
      }

      // Convert the map to a list
      final List<Map<String, dynamic>> donationList = organizedDonations.entries.map((entry) {
        return {
          'username': entry.key as String,
          'amount': entry.value as int,
        };
      }).toList();

      return donationList;
    } catch (e) {
      print('Error organizing donations: $e');
      return [];
    }
  }



  /// Show a message using a Snackbar
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  String formatAmount(int amount) {
    if (amount >= 1000000) {
      double result = double.parse((amount / 1000000).toStringAsFixed(2));
      // If the result is a whole number, remove the decimal
      return result == result.toInt().toDouble()
          ? '${result.toInt()}M' // No decimal places for whole numbers
          : '${result.toStringAsFixed(1)}M'; // Otherwise, show one decimal place
    } else if (amount >= 1000) {
      double result = amount / 1000;
      // If the result is a whole number, remove the decimal
      return result == result.toInt().toDouble()
          ? '${result.toInt()}k' // No decimal places for whole numbers
          : '${result.toStringAsFixed(1)}k'; // Otherwise, show one decimal place
    } else {
      return amount.toString(); // No abbreviation for values < 1000
    }
  }




  List<Map<String, dynamic>> aggregateSingleDonationItemFromDonations(
      List<Map<String, dynamic>> donations, int donationItemId) {
    final Map<String, Map<String, dynamic>> aggregatedItems = {};
    List<Map<String, dynamic>> tempDonators=[];
    for (var donation in donations) {
      final username = donation['username'];
      final tempDonationItemId = donation['donation_item_id'];
      if (tempDonationItemId == donationItemId) {
        tempDonators.add({
          'username': username,
          'amount': donation['amount'],
          'color': charts.MaterialPalette.green.shadeDefault,
          'description': donation['description'], // Optional: Add a description if necessary
        });
      }
    }

    // Convert the aggregated map to a list and sort by amount in descending order
    final List<Map<String, dynamic>> aggregatedList = aggregatedItems.values.toList();
    // aggregatedList.sort((a, b) => b['amount'].compareTo(a['amount']));
    return tempDonators;
  }
  Map<String, dynamic> aggregateDonationByUsername(
      List<Map<String, dynamic>> donations, String username) {
    // Initialize variables to store total amount and donation list
    int totalAmount = 0;
    List<Map<String, dynamic>> userDonations = [];

    for (var donation in donations) {
      if (donation['username'] == username) {
        totalAmount += donation['amount'] as int;
        userDonations.add(donation);
      }
    }

    // Create the aggregated result
    return {
      'username': username,
      'totalAmount': totalAmount,
      'donations': userDonations,
    };
  }


  void findTopDonatorUsername(List<Map<String,dynamic>> donators){
    String tempusername='';
    int temp=0;
    for(var donator in donators){
      if(temp<donator['amount']){
        temp=donator['amount'];
        tempusername=donator['username'];
      }
    }
    topDonatorUsername=tempusername;
    setState(() {
      print("Top Donator : $topDonatorUsername");
    });
  }

  Widget buildLeaderboard({required List<Map<String, dynamic>> data,Color cardColor = Colors.white,Color textColor = Colors.black,double height = 300}) {
    // Sort the data by amount in descending order
    data.sort((a, b) {
      final amountA = a['amount'] as int;
      final amountB = b['amount'] as int;
      return amountB.compareTo(amountA); // Descending order
    });

    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.teal.shade100.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: data.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard,
              size: 48,
              color: Colors.grey.shade600,
            ),
            SizedBox(height: 16),
            Text(
              "No data available",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Be the first to add a score!",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      )
          : ClipRRect(
              borderRadius: BorderRadius.circular(20),

            child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
            final rank = index + 1;
            final name = data[index]['username'] as String;
            final score = data[index]['amount'] as int;

            // Styles for the top three ranks
            BoxDecoration decoration;
            TextStyle rankStyle;
            TextStyle nameStyle;
            TextStyle scoreStyle;
            Color rankColor;
            EdgeInsets margin;

            if (rank == 1) {
              margin=EdgeInsets.symmetric(horizontal: 0.0,vertical: 5);
              decoration = BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.yellow.shade700, Colors.orange.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.6),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              );
              rankStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white);
              nameStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white);
              scoreStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade50);
              rankColor = Colors.yellow.shade900;
            } else if (rank == 2) {
              margin=EdgeInsets.symmetric(horizontal: 6.0,vertical: 5);
              decoration = BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade500, Colors.grey.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              );
              rankStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white);
              nameStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white);
              scoreStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.green.shade50);
              rankColor = Colors.grey.shade700;
            } else if (rank == 3) {
              margin=EdgeInsets.symmetric(horizontal: 10.0,vertical: 5);
              decoration = BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown.shade300, Colors.brown.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.4),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              );
              rankStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);
              nameStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);
              scoreStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.green.shade50);
              rankColor = Colors.brown.shade600;
            } else {
              margin=EdgeInsets.symmetric(horizontal: 15.0,vertical: 5);
              decoration = BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              );
              rankStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor);
              nameStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor);
              scoreStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor);
              rankColor = Colors.blue;
            }
            return Container(
              margin: margin,
              decoration: decoration,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                leading: CircleAvatar(
                  backgroundColor: rankColor,
                  radius: 20,
                  child: Text(
                    rank.toString(),
                    style: rankStyle,
                  ),
                ),
                title: Text(
                  name,
                  style: nameStyle,
                ),
                trailing: Text(
                  "${formatAmount(score)} \$",
                  style: scoreStyle,
                ),
              ),
            );
                    },
                  ),
          ),
    );
  }
  Widget buildDonationCarousel({double height=200}) {
    if(_isCarouselCardLoading){
      return Container(
        height: height,
        child: Center(
          child: CircularProgressIndicator(
          ),
        ),
      );
    }else{
      if (_donationItems.isEmpty) {
        // Handle empty list
        return Container(
          height: height,
          child: const Center(
            child: Text(
              'No donation items available.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        );
      }

      if (_donationItems.length == 1) {
        // Handle single item
        final item = _donationItems[0];
        return SizedBox(
          height: height, // Match the height of the carousel
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: CarouselCard(
              id: item['id'] ?? -1,
              imagePath: item['image_path'] ?? 'assets/default.jpg',
              title: item['title'] ?? 'Donation Item',
              amount: item['amount'] ?? 0,
              goal:  item['goal'] ?? 0,
              description: item['description'] ?? '',
              statisticsData: aggregateSingleDonationItemFromDonations(_donations, item['id']),
              timerDuration: item['timer'] ?? '00:00:00',
              isActive: item['is_active'] ?? false,
            ),
          ),
        );
      }

      // Handle multiple items
      return CarouselSlider(
        options: CarouselOptions(
            height: height,
            autoPlay: true,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            pauseAutoPlayOnTouch: true
        ),
        items: List.generate(
          _donationItems.length,
              (index) {
            final item = _donationItems[index];
            return CarouselCard(
              id: item['id'] ?? -1,
              imagePath: item['image_path'] ?? 'assets/default.jpg',
              title: item['title'] ?? 'Donation Item',
              amount: item['amount'] ?? 0,
              goal:  item['goal'] ?? 0,
              description: item['description'] ?? '',
              statisticsData:  aggregateSingleDonationItemFromDonations(_donations, item['id']),
              timerDuration: item['timer'] ?? '00:00:00',
              isActive: item['is_active'] ?? false,
            );
          },
        ),
      );
    }
  }
  Widget _sectionHeader(String title, IconData icon,{double fontSize=22}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal,size: fontSize  + 3,),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }
  void _showAddDonationDialog() {
    final TextEditingController _amountController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();  // New controller for description
    Map<String, dynamic>? selectedCategory;
    int? selectedPredefinedAmount;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Add a Donation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pre-defined Amount Buttons
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 8.0,
                      children: [100, 500, 1000, 10000, 100000].map((amount) {
                        return ChoiceChip(
                          label: Text("\$${formatAmount(amount)}"),
                          selected: selectedPredefinedAmount == amount,
                          onSelected: (selected) {
                            setState(() {
                              selectedPredefinedAmount = selected ? amount : null;
                              _amountController.clear(); // Clear custom amount
                            });
                          },
                          selectedColor: Colors.teal.shade700,
                          labelStyle: TextStyle(
                            color: selectedPredefinedAmount == amount
                                ? Colors.white
                                : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Custom Amount Field
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        setState(() {
                          selectedPredefinedAmount = null; // Clear pre-defined selection
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Custom Amount',
                        hintText: 'Enter donation amount',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Menu for Category
                    DropdownButtonFormField<Map<String, dynamic>>(
                      borderRadius: BorderRadius.circular(20),
                      value: selectedCategory,
                      items: _donationItems.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category['title']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Category',
                        hintText: 'Select a donation category',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,  // Allow multi-line input
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Write your thoughts about the donation',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cancel Button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    // Add Button
                    ElevatedButton(
                      onPressed: () {
                        // Determine amount
                        final amount = selectedPredefinedAmount ??
                            int.tryParse(_amountController.text.trim());

                        if (amount == null || selectedCategory == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all fields.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        // Get the description text
                        final description = _descriptionController.text.trim();

                        // Insert donation with description
                        _insertDonation(
                          amount: amount,
                          category: selectedCategory!['id'],
                          description: description,  // Pass the description
                        );

                        Navigator.of(context).pop(); // Close dialog

                        // Notify parent widget
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      drawer: DonationAppDrawer(topDonatorUsername: topDonatorUsername,),
      appBar: AppBar(
        title: const Text('Donations'),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: (){},
              icon: Icon(
                  Icons.account_circle_rounded,
                color: Colors.black,
              )
          )
        ],
      ),

      body: Stack(
        children: [
          // Main donation page
          RefreshIndicator(
            onRefresh: () async {
              // Simulate refreshing data
              await _refreshData();
              setState(() {

              });
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  // Carousel Slider
                  buildDonationCarousel(height: screenSize.height * .25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
                    child: Divider(),
                  ),
                  SizedBox(height: screenSize.height * .015),

                  // Leaderboard Section
                  _sectionHeader('Leaderboard', Icons.leaderboard),
                  SizedBox(height: screenSize.height * .01),
                  buildLeaderboard(data: _donators, height: screenSize.height * .39),

                  const SizedBox(height: 15),

                  // Donate Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        _showAddDonationDialog();

                        print(aggregateDonationByUsername(_donations,_supabaseClient.auth.currentUser!.userMetadata!['username']));
                        print('----------------------------------------');
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 5, // Add subtle shadow for depth
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25), // Smoother corners
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2, // Slight letter spacing for readability
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.favorite, // Heart icon to symbolize donation
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10), // Space between icon and text
                          const Text(
                            'Donate Now',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // No Internet Connection Overlay
          if (!_isOnline)
            Container(
              color: Colors.black.withOpacity(0.6), // Semi-transparent background
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 50,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No Internet Connection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class CarouselCard extends StatefulWidget {
  final int id;
  final String imagePath;
  final String title;
  final int amount;
  final int goal;
  final String description;
  final List<Map<String,dynamic>> statisticsData;
  final String timerDuration;
  final bool isActive;

  const CarouselCard({
    Key? key,
    required this.id,
    required this.imagePath,
    required this.title,
    required this.amount,
    required this.goal,
    required this.description,
    required this.statisticsData,
    required this.timerDuration,
    required this.isActive
  }) : super(key: key);

  @override
  _CarouselCardState createState() => _CarouselCardState();
}

class _CarouselCardState extends State<CarouselCard> {
  late Duration remainingTime;
  Timer? _timer;
  late bool _isPaused;

  @override
  void initState() {
    super.initState();
    _isPaused=false;
    remainingTime = _calculateRemainingDuration(widget.timerDuration);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (remainingTime.inSeconds > 0) {
            remainingTime -= const Duration(seconds: 1);
          } else {
            _updateDonationItem(widget.id, {'is_active' : false});
            timer.cancel();
          }
        });
      }
    });
  }
  void _StartPauseTimer() {
    if (widget.isActive) {
      if(_isPaused){
        setState(() {
          _isPaused = false;
        });
        _startTimer(); // Restart the timer with the remaining duration
      }else{

      }
    }else if(!widget.isActive){
      if(!_isPaused){
        _timer?.cancel(); // Cancel the current timer
        setState(() {
          _isPaused=true;
        });
      }else{

      }
    }
  }




  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  Future<void> _updateDonationItem(int id,Map<String,dynamic> updatedValues) async {

    try {
      await _supabaseClient.from('donation_items')
          .update(updatedValues)
          .eq('id', id);

    } catch (e) {
      _showMessage('An unexpected error occurred: $e');
    } finally {

    }
  }

  Duration _calculateRemainingDuration(String timestampz) {
    try {
      // Parse the timestamp string into a DateTime object
      final DateTime targetTime = DateTime.parse(timestampz);

      // Get the current time
      final DateTime now = DateTime.now();

      // Calculate the difference
      final Duration remainingDuration = targetTime.difference(now);

      // Ensure non-negative duration
      return remainingDuration.isNegative ? Duration.zero : remainingDuration;
    } catch (e) {
      // Handle any parsing errors
      debugPrint('Error parsing timestampz: $e');
      return Duration.zero;
    }
  }


  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final days = duration.inDays;
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (days > 0) {
      return '$days days | $hours:$minutes:$seconds';
    } else {
      return '$hours:$minutes:$seconds';
    }
  }

  String formatAmount(int amount) {
    if (amount >= 1000000) {
      double result = double.parse((amount / 1000000).toStringAsFixed(2));
      // If the result is a whole number, remove the decimal
      return result == result.toInt().toDouble()
          ? '${result.toInt()}M' // No decimal places for whole numbers
          : '${result.toStringAsFixed(1)}M'; // Otherwise, show one decimal place
    } else if (amount >= 1000) {
      double result = amount / 1000;
      // If the result is a whole number, remove the decimal
      return result == result.toInt().toDouble()
          ? '${result.toInt()}k' // No decimal places for whole numbers
          : '${result.toStringAsFixed(1)}k'; // Otherwise, show one decimal place
    } else {
      return amount.toString(); // No abbreviation for values < 1000
    }
  }


  @override
  Widget build(BuildContext context) {
    remainingTime = _calculateRemainingDuration(widget.timerDuration);
    _StartPauseTimer();
    return GestureDetector(
      onTap: !widget.isActive ? null : () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => DonationStatisticsPage(id: widget.id,pic: widget.imagePath,title: widget.title, amountRaised: widget.amount, goal: widget.goal,description: widget.description, statisticsData: widget.statisticsData),));
      },
      child: Container(
        height: 200, // Set a fixed height
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Background Image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  widget.imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/default.jpg',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),

            // Title Overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Display "Active" badge if isActive is true
                    if (widget.isActive)
                      if(widget.amount < widget.goal)...[
                        Row(
                          children: [
                            Container(
                              padding:
                              const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child:  Text(
                                "${formatAmount(widget.amount)} \$",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(Icons.keyboard_double_arrow_right,weight: 50,color: Colors.white,),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child:  Text(
                                "${formatAmount(widget.goal)} \$",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      ]else...[
                        Container(
                          padding:
                          const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child:  Text(
                            "${formatAmount(widget.amount)} \$",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]
                    // Container(
                    //   padding:
                    //   const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                    //   decoration: BoxDecoration(
                    //     color: Colors.green,
                    //     borderRadius: BorderRadius.circular(5),
                    //   ),
                    //   child: const Text(
                    //     "Active",
                    //     style: TextStyle(
                    //       color: Colors.white,
                    //       fontSize: 12,
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),

            // Timer Positioned on Top Right
            if(widget.isActive)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    _formatDuration(remainingTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Dimmed Overlay if isActive is false
            if (!widget.isActive)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6), // Dims the entire card
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    "Inactive",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



