import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:donation_app_v1/const_values/donation_card_page_values.dart';
import 'package:donation_app_v1/enums/currency_enum.dart';
import 'package:donation_app_v1/models/donation_bar_chart_model.dart';
import 'package:donation_app_v1/models/settings_model.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:donation_app_v1/qr_code.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';


class DonationStatisticsPage extends StatefulWidget {
  final int id;
  final String title;
  final String pic;
  final int amountRaised;
  final int goal;
  final String description;
  final String timerDuration;
  final List<Map<String, dynamic>> statisticsData;
  final bool isActive;

  DonationStatisticsPage({
    required this.id,
    required this.title,
    required this.amountRaised,
    this.pic="",
    required this.goal,
    required this.description,
    required this.statisticsData,
    required this.timerDuration,
    required this.isActive,
  });

  @override
  State<DonationStatisticsPage> createState() => _DonationStatisticsPageState();
}

class _DonationStatisticsPageState extends State<DonationStatisticsPage> with TickerProviderStateMixin{
  late AnimationController _animationController;
  late Animation<double> _animation;
  late List<Map<String, dynamic>> aggregatedList;
  late Duration remainingTime;
  late Timer _timer;

  @override
  void initState() {
    remainingTime = _calculateRemainingDuration(widget.timerDuration);
    _startTimer();
    _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300)
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    _animationController.forward();
    aggregatedList=aggregateSingleDonationItemFromDonations(widget.statisticsData);
    super.initState();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime.inSeconds > 0) {
        setState(() {
          remainingTime = remainingTime - Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
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
      return '$days ${DetailsCardLabels.getLabel(getCurrentLanguage(), 'timer_days_value')} | $hours:$minutes:$seconds';
    } else {
      return '$hours:$minutes:$seconds';
    }
  }
  String formatAmount(int amount) {
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
  List<Map<String, dynamic>> aggregateSingleDonationItemFromDonations(
      List<Map<String, dynamic>> donations) {
    final Map<String, Map<String, dynamic>> aggregatedItems = {};

    for (var donation in donations) {
      final username = donation['username'];
      if (aggregatedItems.containsKey(username)) {
        // Aggregate the amount for an existing username
        aggregatedItems[username]!['amount'] += donation['amount'];
      } else {
        // Initialize a new entry for this username
        aggregatedItems[username] = {
          'username': username,
          'amount': donation['amount'],
          'color': charts.MaterialPalette.teal.shadeDefault,
          'description': donation['description'], // Optional: Add a description if necessary
        };
      }
    }

    // Convert the aggregated map to a list and sort by amount in descending order
    final List<Map<String, dynamic>> aggregatedList = aggregatedItems.values.toList();
    aggregatedList.sort((a, b) => b['amount'].compareTo(a['amount']));

    print('Niaou : ${aggregatedList.toString()}'); // Debug: Print the sorted list

    return aggregatedList;
  }
  charts.Color getRandomMaterialPaletteColor() {
    final List<charts.Color> paletteColors = [
      charts.MaterialPalette.blue.shadeDefault,
      charts.MaterialPalette.red.shadeDefault,
      charts.MaterialPalette.green.shadeDefault,
      charts.MaterialPalette.yellow.shadeDefault,
      charts.MaterialPalette.purple.shadeDefault,
      charts.MaterialPalette.cyan.shadeDefault,
      charts.MaterialPalette.indigo.shadeDefault,
      charts.MaterialPalette.deepOrange.shadeDefault,
      charts.MaterialPalette.lime.shadeDefault,
    ];

    final Random random = Random();
    return paletteColors[random.nextInt(paletteColors.length)];
  }


  @override
  Widget build(BuildContext context) {



    print(widget.amountRaised);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.teal.shade600,
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
                style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.white12)
                ),
                color: Colors.black87,
                onPressed: () {
                  Map<String,dynamic> tempData={'id': widget.id,'title' : widget.title,'amount_raised' : widget.amountRaised , 'pic' : widget.pic};
                  print(tempData);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => QRCodeScannerPage(data: tempData,),));
                },
                icon: Icon(Icons.qr_code,)
            ),
          ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0,vertical: 0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Page Title and Description
                SizedBox(height: 16.0),

                SizedBox(height: 10.0),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Icon Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DetailsCardLabels.getLabel(getCurrentLanguage(), 'campaign_progress_value'),
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                              ),
                            ),
                            Icon(
                              Icons.trending_up,
                              color: Colors.teal,
                              size: 28.0,
                            ),
                          ],
                        ),
                        SizedBox(height: 12.0),

                        // Progress Bar with Percentage
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                borderRadius: BorderRadius.circular(10),
                                value: widget.amountRaised / widget.goal,
                                minHeight: 25,
                                color: Colors.teal,
                                backgroundColor: Colors.grey[300],
                              ),
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Text((((widget.amountRaised / widget.goal) * 100) >= 100) ? DetailsCardLabels.getLabel(getCurrentLanguage(), 'completed_text_value') :
                                "${((widget.amountRaised / widget.goal) * 100).toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: ((widget.amountRaised / widget.goal) * 100) > 60 ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.0),

                        // Amount Raised and Goal Summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DetailsCardLabels.getLabel(getCurrentLanguage(), 'raised_text_value'),
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  "${formatAmount(widget.amountRaised,)}",
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 40.0,
                              width: 2.0,
                              color: Colors.grey.shade300, // Divider line
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  DetailsCardLabels.getLabel(getCurrentLanguage(), 'goal_text_value'),
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  "${formatAmount(widget.goal)}",
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        if(widget.isActive)
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "⏳ ${DetailsCardLabels.getLabel(getCurrentLanguage(), 'time_left_text_value')}: ${_formatDuration(remainingTime)}",
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                Divider(color: Colors.grey.shade400),

                Text(
                  DetailsCardLabels.getLabel(getCurrentLanguage(), 'description_title_value'),
                  style: TextStyle(
                    fontSize: 26.0, // Slightly larger for prominence
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade900, // Darker shade for a more elegant look
                    letterSpacing: 1.2, // Add some spacing for better readability
                  ),
                ),
                SizedBox(height: 12.0), // Reduce padding for tighter design
                Container(
                  padding: EdgeInsets.all(12.0), // Add some padding for a cleaner container look
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50, // Subtle background to highlight text
                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                    border: Border.all(color: Colors.teal.shade200), // Soft border for separation
                  ),
                  child: Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 16.0,
                      height: 1.5, // Line height for better readability
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                Divider(color: Colors.grey.shade400),

                // Donation Breakdown Chart
                Text(
                  DetailsCardLabels.getLabel(getCurrentLanguage(), 'donation_breakdown_value'),
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
                SizedBox(height: 10.0),
                if(aggregatedList.isNotEmpty)...[
                  SizedBox(
                    child: DonationBarChart(
                      width: MediaQuery.of(context).size.width * .6,
                      height: MediaQuery.of(context).size.height * .07,
                      duration: Duration(milliseconds: 300),
                      animation: _animation,
                      animationController: _animationController,
                      data: aggregatedList,
                      minY: 0,
                      maxY: double.parse((aggregatedList.first['amount'] + 1000).toString()),
                      showBarTouchData: true,
                    ),
                  ),
                ],
                SizedBox(height: 20.0),

                // Donation Items with Description
                Text(
                  DetailsCardLabels.getLabel(getCurrentLanguage(), 'donation_itme_details_value'),
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
                SizedBox(height: 16.0), // Better spacing
                Container(
                  height: MediaQuery.of(context).size.height * .4, // Adjustable height
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade200, // Frosted glass effect
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: widget.statisticsData.isEmpty
                      ? Center(
                    child: Text(
                      DetailsCardLabels.getLabel(getCurrentLanguage(), 'no_donations_text_value'),
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      : ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    separatorBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Divider(color: Colors.teal.shade100, thickness: 1),
                    ),
                    itemCount: widget.statisticsData.length,
                    itemBuilder: (context, index) {
                      final item = widget.statisticsData[index];
                      return Card(
                        elevation: 3.0,
                        margin: EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        color: Colors.white, // White background for contrast
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          child: Row(
                            children: [
                              // Profile Avatar
                              CircleAvatar(
                                radius: 28.0,
                                backgroundColor: Colors.teal.shade700,
                                child: Text(
                                  item['username'][0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 14.0),

                              // User Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['username'],
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade900,
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    Text(
                                      item['description'] ?? "No description provided",
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.teal.shade600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Donation Amount
                              SizedBox(width: 12.0),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  "${formatAmount(item['amount'])}", // Formats large numbers
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }


}


