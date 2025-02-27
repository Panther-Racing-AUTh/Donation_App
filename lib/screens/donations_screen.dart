import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:donation_app_v1/const_values/home_page_values.dart';
import 'package:donation_app_v1/const_values/title_values.dart';
import 'package:donation_app_v1/enums/card_type_enum.dart';
import 'package:donation_app_v1/enums/currency_enum.dart';
import 'package:donation_app_v1/enums/drawer_enum.dart';
import 'package:donation_app_v1/enums/language_enum.dart';
import 'package:donation_app_v1/main.dart';
import 'package:donation_app_v1/models/card_model.dart';
import 'package:donation_app_v1/models/carousel_card_model.dart';
import 'package:donation_app_v1/models/profile_model.dart';
import 'package:donation_app_v1/models/settings_model.dart';
import 'package:donation_app_v1/notification_functions.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:donation_app_v1/screens/donation_card_screen.dart';
import 'package:donation_app_v1/models/drawer_model.dart';
import 'package:donation_app_v1/screens/profile_screen.dart';
import 'package:donation_app_v1/screens/signature_screen.dart';
import 'package:donation_app_v1/temp/page/pdf_page.dart';
import 'package:donation_app_v1/widgets/wallet_widget.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:workmanager/workmanager.dart';




final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client

class DonationsPage extends StatefulWidget {
  @override
  _DonationsPageState createState() => _DonationsPageState();
}

class _DonationsPageState extends State<DonationsPage> with WidgetsBindingObserver{
  final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client
  late RealtimeChannel channelDonation;
  late RealtimeChannel channelDonationItem;


  AppLifecycleState? _lastLifecycleState;


  List<Map<String, dynamic>> _donations = [];
  List<Map<String,dynamic>>  _donators=[];
  List<Map<String, dynamic>> _donationItems = [];
  List<Map<String,dynamic>> _translations = [];
  List<String> _donation_item_images=[];
  String topDonatorUsername='';

  bool _isOnline=true;
  bool _isLoading = false;
  bool _isCarouselCardLoading=false;
  bool isInBackground = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  late Timer _timerConnectionCheck;
  bool _hasImageError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to call Provider.of or similar context-based functions here
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _timerConnectionCheck.cancel();
    channelDonation.unsubscribe();
    channelDonationItem.unsubscribe();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lastLifecycleState = state;
    print('Current app lifecycle state: $_lastLifecycleState');
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

  void onDonationMade() {
    Future.delayed(Duration(seconds: 3));
    // Check if the app is not in the foreground.
    if (_lastLifecycleState == AppLifecycleState.paused ||
        _lastLifecycleState == AppLifecycleState.inactive ||
        _lastLifecycleState == AppLifecycleState.detached) {
      // Trigger a local notification.
      _showNotification();
    } else {
      // Optionally, update the UI or show an in-app message.
      print('Donation made while app is active.');
    }
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'donation_channel', // channel id
      'Donations', // channel name
      channelDescription: 'Notifications for donation confirmations',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID.
      'Donation Successful',
      'Thank you for your donation!',
      notificationDetails,
      payload: 'donation_payload', // Optional payload.
    );
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
  Future<void> _fetchProfile() async {
    ProfileProvider profileProvider=Provider.of<ProfileProvider>(context,listen: false);
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('username', _supabaseClient.auth.currentUser!.userMetadata!['username']);

      if (response.isNotEmpty) {
        setState(() {
          profileProvider.updateProfile(Profile.fromJson(response.first));
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

  }

  Future<void> _fetchDonationItems() async {
    try {
      setState(() {
        _isCarouselCardLoading = true;
      });

      // Fetch donation items with translations
      final response = await _supabaseClient
          .from('donation_items')
          .select('id, image_path, translation, amount, goal, timer, is_active')
          .order('created_at', ascending: false);

      if (response != null && response.isNotEmpty) {
        setState(() {
          // Cast the response to List<Map<String, dynamic>>
          _donationItems = List<Map<String, dynamic>>.from(response);

          // Extract and map translations for easier access
          _translations = _donationItems.map((item) {
            return {
              'id': item['id'],
              ...Map<String, dynamic>.from(item['translation']), // Ensure correct type
            };
          }).toList();
        });
      } else {
        _showMessage('No donation items found.');
      }
    } catch (e) {
      _showMessage('An unexpected error occurred: $e');
    } finally {
      // Ensure the loading flag is reset regardless of success or error
      setState(() {
        _isCarouselCardLoading = false;
      });
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
  Future<void> _insertDonation({
    int amount = 0,
    required int category,
    String description = '',
    Map<String,dynamic>? paymentMethod, // Added parameter
  }) async {
    setState(() {
      _isLoading = true;
    });

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
        "username": _supabaseClient.auth.currentUser!.userMetadata!['username'] ?? "User",
        "email": _supabaseClient.auth.currentUser!.email,
        "amount": amount,
        "created_at": DateTime.now().toIso8601String(),
        "donation_item_id": category,
        "description": description,
        "profile_id": profileId,
        "payment_method": paymentMethod, // Save the payment method (card number)
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
  // Send Notification After 10s


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
          onDonationMade();
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

  Future<String?> fetchImageUrlByUsername(String username) async {
    final response = await _supabaseClient
        .from('profiles')
        .select('image_url')
        .eq('uuid', _supabaseClient.auth.currentUser!.id)
        .single();

    if (response.isEmpty) {
      print('Error fetching image URL: ${response}');
      return null;
    }

    // Assuming response.data is a Map<String, dynamic> containing the image_url
    return response['image_url'] as String?;
  }

  /// Show a message using a Snackbar
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  String formatAmount(int amount) {
    final profileProvider= Provider.of<ProfileProvider>(context,listen: false);
    final currentCurrency = Currency.values.firstWhere((element) => element.code == profileProvider.profile!.settings.currency);
    final currencyFormat = currentCurrency.format(amount.toDouble());
    if (amount >= 1000000) {
      double result = amount / 1000000;
      return result == result.toInt().toDouble()
          ? '${currentCurrency.symbol} ${currentCurrency.convert(result.toDouble(),currentCurrency).toInt()}M'
          : '${currentCurrency.symbol} ${currentCurrency.convert(result.toDouble(),currentCurrency).toInt().toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      double result = amount / 1000;
      return result == result.toInt().toDouble()
          ? '${currentCurrency.symbol} ${currentCurrency.convert(result.toDouble(),currentCurrency).toInt()}k'
          : '${currentCurrency.symbol} ${currentCurrency.convert(result.toDouble(),currentCurrency).toInt().toStringAsFixed(1)}k';
    } else {
      return  "${currentCurrency.symbol} ${currentCurrency.convert(amount.toDouble(),currentCurrency).toInt()}";
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

  Widget buildLeaderboard({
    required List<Map<String, dynamic>> data,
    Color cardColor = Colors.white,
    Color textColor = Colors.black,
    double height = 300,
  }) {
    // Sort the data by amount in descending order
    data.sort((a, b) {
      final amountA = a['amount'] as int;
      final amountB = b['amount'] as int;
      return amountB.compareTo(amountA); // Descending order
    });

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade900, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
            const SizedBox(height: 16),
            Text(
              DonationLabels.getLabel(getCurrentLanguage(), 'no_data_available'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DonationLabels.getLabel(getCurrentLanguage(), 'first_to_add_score'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      )
          :             ClipRRect(
        borderRadius: BorderRadius.circular(20),

        child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final rank = index + 1;
                final name = data[index]['username'] as String;
                final score = data[index]['amount'] as int;


                BoxDecoration decoration;
                TextStyle rankStyle;
                TextStyle nameStyle;
                TextStyle scoreStyle;
                Color rankColor;

                if (rank == 1) {
                  decoration = BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.yellow.shade700, Colors.orange.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  );
                  rankStyle = const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white);
                  nameStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white);
                  scoreStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade50);
                  rankColor = Colors.orange.shade900;
                } else if (rank == 2) {
                  decoration = BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade500, Colors.grey.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  );
                  rankStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white);
                  nameStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white);
                  scoreStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.green.shade50);
                  rankColor = Colors.grey.shade700;
                } else if (rank == 3) {
                  decoration = BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.brown.shade300, Colors.brown.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  );
                  rankStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white);
                  nameStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);
                  scoreStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.green.shade50);
                  rankColor = Colors.brown.shade600;
                } else {
                  decoration = BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  );
                  rankStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black);
                  nameStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor);
                  scoreStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor);
                  rankColor = Colors.white;
                }
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8,horizontal: 8),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: rankColor,
                      borderRadius: BorderRadius.circular(12),

                    ),
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: Container(
                        width: 80,
                        child: Row(
                          children: [
                            Text(
                              rank.toString(),
                              style: rankStyle,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.teal.shade300,
                              backgroundImage: AssetImage('assets/profile_placeholder.png'), // Replace with actual image path
                            ),
                          ],
                        ),
                      ),
                      title: Text(
                        name,
                        style: nameStyle,
                      ),
                      trailing: Text(
                        "${formatAmount(score)}",
                        style: scoreStyle,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

    );
  }
  String getCurrentLanguage()  {
    // Ensure that the Hive box is open. If already open, this returns the box immediately.
    final Box<Settings> settingsBox = Hive.box<Settings>('settingsBox');

    // Retrieve stored settings or use default settings if none are stored.
    final Settings settings = settingsBox.get('userSettings', defaultValue: Settings.defaultSettings)!;

    // Return the current language as an enum.
    return  settings.language;
  }

  Widget buildDonationCarousel({double height = 200}) {
    if (_isCarouselCardLoading) {
      return Container(
        height: height,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      if (_donationItems.isEmpty) {
        // Handle empty list
        return Container(
          height: height,
          child: Center(
            child: Text(
              DonationLabels.getLabel(getCurrentLanguage(), 'no_donation_items'),
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        );
      }

      if (_donationItems.length == 1) {
        // Handle single item
        final item = _donationItems[0];
        final translationItem = _translations[0];
        return SizedBox(
          height: height, // Match the height of the carousel
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: CarouselCard(
              id: item['id'] ?? -1,
              imagePath: item['image_path'] ?? 'assets/default.jpg',
              title: translationItem[getCurrentLanguage()]['title'],
              amount: item['amount'] ?? 0,
              goal: item['goal'] ?? 0,
              description: translationItem[getCurrentLanguage()]['description'],
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
          pauseAutoPlayOnTouch: true,
        ),
        items: List.generate(
          _donationItems.length,
              (index) {
            final item = _donationItems[index];
            return CarouselCard(
              id: item['id'] ?? -1,
              imagePath: item['image_path'] ?? 'assets/default.jpg',
              title: _translations[index][getCurrentLanguage()]['title'],
              amount: item['amount'] ?? 0,
              goal: item['goal'] ?? 0,
              description: _translations[index][getCurrentLanguage()]['description'],
              statisticsData: aggregateSingleDonationItemFromDonations(_donations, item['id']),
              timerDuration: item['timer'] ?? '00:00:00',
              isActive: item['is_active'] ?? false,
            );
          },
        ),
      );
    }
  }

// Helper method for translations
  String _getTranslation(Map<String, dynamic> item, String key) {
    try {
      // Ensure translation exists and handle language-specific fetching
      final translation = item['translation'];
      final currentLanguage = getCurrentLanguage().toString();  // Ensure this is the current language

      // Check if translation for the current language exists
      if (translation != null && translation.containsKey(currentLanguage)) {
        final langData = translation[currentLanguage];
        if (langData != null && langData.containsKey(key)) {
          return langData[key] ?? '';  // Return the translation or empty string if key is missing
        }
      }
      // Fallback if translation or key is not found
      return 'Translation not available';
    } catch (e) {
      // Handle any errors gracefully and return fallback message
      print("Error fetching translation for $key: $e");
      return 'Translation not available';
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
  Future<void> removePaymentCard(PaymentCard cardToRemove) async {
    ProfileProvider profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    try {
      // Get the current user
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated.");
      }

      // Remove the card from the profile provider's payment cards list
      profileProvider.profile!.paymentCards.removeWhere(
            (card) => card.cardNumber == cardToRemove.cardNumber &&
            card.expirationDate == cardToRemove.expirationDate &&
            card.uuid == cardToRemove.uuid,
      );

      // Get the updated list of cards
      List<dynamic> updatedCards = convertCardsToJson(profileProvider.profile!.paymentCards) ?? [];

      // Update the database with the new list of cards
      await _supabaseClient
          .from('profiles')
          .update({'payment_cards': updatedCards})
          .eq('username', user.userMetadata?['username']);

      _showMessage("Card removed successfully!");
    } catch (e) {
      print("Error removing card: $e");
      _showMessage("Failed to remove card. Please try again.");
    }
  }

  Future<void> addPaymentCard(PaymentCard newCard) async {
    ProfileProvider profileProvider=Provider.of<ProfileProvider>(context,listen: false);
    try {
      // Get the current user
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated.");
      }
      profileProvider.profile!.paymentCards.add(newCard);

      // Get the existing cards or initialize an empty list
      List<dynamic> existingCards = convertCardsToJson(profileProvider.profile!.paymentCards) ?? [];


      // Update the profile with the new list of cards
      await _supabaseClient
          .from('profiles')
          .update({'payment_cards': existingCards})
          .eq('username', user.userMetadata?['username']);

      _showMessage("Card added successfully!");
    } catch (e) {
      print("Error adding card: $e");
      _showMessage("Failed to add card. Please try again.");
    }
  }
  void _addCard() {
    showDialog(
      context: context,
      builder: (context) {
        return AddCardDialog(
          onSave: (cardData) {
            setState(() {
              addPaymentCard(cardData);
            });
          },
        );
      },
    );
  }

  void _showAddDonationDialog() {
    ProfileProvider profileProvider=Provider.of<ProfileProvider>(context,listen: false);

    // Check if payment cards exist in the profile.
    final paymentCards = profileProvider.profile!.paymentCards;
    final bool hasCards = paymentCards != null && (paymentCards as List).isNotEmpty;

    if (!hasCards) {
      // Show dialog prompting user to add a card
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              DonationLabels.getLabel(getCurrentLanguage(), 'no_payment_method_title_value'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            content: Text(DonationLabels.getLabel(getCurrentLanguage(), 'no_payment_method_description_value')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(DonationLabels.getLabel(getCurrentLanguage(), 'cancel_button'), style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to the add card screen or show the add card dialog here.
                  _addCard();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(DonationLabels.getLabel(getCurrentLanguage(), 'add_card_button'), style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      );
      return;
    }

    // Otherwise, show the donation dialog.
    final TextEditingController _amountController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();
    Map<String, dynamic>? selectedCategory;
    int? selectedPredefinedAmount;
    PaymentCard? selectedCard; // Selected card variable

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              contentPadding: EdgeInsets.all(12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                DonationLabels.getLabel(getCurrentLanguage(), 'make_a_donation_value'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Predefined Amount Buttons
// Predefined Amount Buttons
                    // Predefined Amount Buttons with Custom Option
                     // Category Dropdown
                    DropdownButtonFormField<Map<String, dynamic>>(
                      borderRadius: BorderRadius.circular(20),
                      value: selectedCategory,
                      items: _donationItems.where((category1) => category1['is_active'] == true).map((category) {
                        // Add null checks to avoid accessing null values
                        final translation = category['translation'];
                        final currentLanguage = getCurrentLanguage();

                        // Check if translation and currentLanguage are not null
                        String title = translation?[currentLanguage]?['title'] ?? 'No Title'; // Default fallback

                        return DropdownMenuItem(
                          value: category,
                          child: Container(
                            width: 180,
                            child: Text(
                              title,
                              style: TextStyle(overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: DonationLabels.getLabel(
                            getCurrentLanguage(),
                            'donation_category_hint_value'
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description Field
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: DonationLabels.getLabel(getCurrentLanguage(), 'description_hint_value'),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Payment Method Selection Dropdown
                    DropdownButtonFormField<PaymentCard>(
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(20),
                      value: selectedCard,
                      items: profileProvider.profile!.paymentCards.map((card) {
                        return DropdownMenuItem<PaymentCard>(
                          value: card,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              card.cardType.getIcon(color: Colors.teal),
                              const SizedBox(width: 10),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    "**** **** **** ${card.cardNumber.substring(card.cardNumber.length - 4)}",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCard = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: DonationLabels.getLabel(getCurrentLanguage(), 'payment_method_hint_value'),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 10.0,
                      runSpacing: 8.0,
                      children: [
                        100,
                        500,
                        1000,
                        10000,
                        100000,
                        -1 // Add -1 for the "Custom" choice
                      ].map((amount) {
                        return ChoiceChip(
                          label: Text(amount == -1
                              ? DonationLabels.getLabel(getCurrentLanguage(), 'custom_amount_label_value') // Label for "Custom"
                              : "${formatAmount(amount)}"), // Format predefined amounts
                          selected: selectedPredefinedAmount == amount,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedPredefinedAmount = amount;
                                if (amount == -1) {
                                  _amountController.clear(); // Clear input for fresh custom entry
                                }
                              } else {
                                selectedPredefinedAmount = null;
                              }
                            });
                          },
                          selectedColor: Colors.teal,
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: selectedPredefinedAmount == amount ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

// Custom Amount Input (Shown Only for "Custom" Choice)
                    if (selectedPredefinedAmount == -1)
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            if (value.isNotEmpty) {
                              selectedPredefinedAmount = -1; // Ensure the "Custom" chip remains selected
                            }
                          });
                        },
                        decoration: InputDecoration(
                          labelText: DonationLabels.getLabel(getCurrentLanguage(), 'custom_amount_label_value'),
                          prefixIcon: Icon(Icons.attach_money, color: Colors.teal),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),


                  ],
                ),
              ),
              actions: [
                // Cancel Button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(DonationLabels.getLabel(getCurrentLanguage(), 'cancel_button'), style: TextStyle(color: Colors.red)),
                ),
                // Add Donation Button
                ElevatedButton(
                  onPressed: () {
                    // Final amount validation
                    final amount = selectedPredefinedAmount == -1
                        ? int.tryParse(_amountController.text.trim()) // Use custom input if "Custom" is selected
                        : selectedPredefinedAmount;

                    if (amount == null || amount <= 0 || selectedCategory == null || selectedCard == null) {
                      // Show error message if any field is invalid
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields with valid data.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return; // Stop further execution if fields are invalid
                    }

                    final description = _descriptionController.text.trim();

                    // Insert the donation details since validation passed
                    _insertDonation(
                      amount: amount,
                      category: selectedCategory!['id'],
                      description: description,
                      paymentMethod: selectedCard!.toJson(), // Pass the card details as JSON
                    );

                    // Close the dialog after successful donation
                    Navigator.of(context).pop();

                    // Optionally show a success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Donation added successfully!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(DonationLabels.getLabel(getCurrentLanguage(), 'donate_button'), style: TextStyle(fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Dummy function to represent the add card dialog.
// Replace this with your actual implementation.
  void _showAddCardDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Payment Card'),
          content: const Text('Implement your add card functionality here.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    ProfileProvider profileProvider=Provider.of<ProfileProvider>(context,listen: false);

    Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      drawer: DonationAppDrawer(topDonatorUsername: topDonatorUsername,drawerIndex: DrawerItem.home.index,),
      appBar: AppBar(
        title:  Text(PageTitles.getTitle(getCurrentLanguage(), 'home_page_title'),style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.all(5),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(isTopDonator: _supabaseClient.auth.currentUser!.userMetadata!['username'] == topDonatorUsername)),
                );
              },
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child:  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.teal.shade700,
                    foregroundImage: _hasImageError
                        ? AssetImage('assets/images/default.png')
                        : NetworkImage(profileProvider.profile!.imageUrl) as ImageProvider,
                    onForegroundImageError: (exception, stackTrace) {
                      // When error occurs, update state to show fallback text.
                      setState(() {
                        _hasImageError = true;
                      });
                      print("Error loading image: $exception");
                    },
                    child: _hasImageError
                        ? Text(
                      ( _supabaseClient.auth.currentUser!.userMetadata!['username'] ?? "User" )[0].toUpperCase(),
                      style: const TextStyle(

                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    )
                        : null,
                  )
              ),
            ),
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
                  _sectionHeader(DonationLabels.getLabel(getCurrentLanguage(), 'leaderboard_value'), Icons.leaderboard),
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
                        //Navigator.push(context, MaterialPageRoute(builder: (context) => PdfPage (),));

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
                          Text(
                            DonationLabels.getLabel(getCurrentLanguage(), 'donate_now_value'),
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
                    Text(
                      DonationLabels.getLabel(getCurrentLanguage(), 'no_internet_connection'),
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

