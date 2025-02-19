import 'dart:io';
import 'dart:math';

import 'package:donation_app_v1/qr_code.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:qr_flutter/qr_flutter.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';


class DonationStatisticsPage extends StatefulWidget {
  final int id;
  final String title;
  final String pic;
  final int amountRaised;
  final int goal;
  final String description;
  final List<Map<String, dynamic>> statisticsData;

  DonationStatisticsPage({
    required this.id,
    required this.title,
    required this.amountRaised,
    this.pic="",
    required this.goal,
    required this.description,
    required this.statisticsData,
  });

  @override
  State<DonationStatisticsPage> createState() => _DonationStatisticsPageState();
}

class _DonationStatisticsPageState extends State<DonationStatisticsPage> with TickerProviderStateMixin{
  late AnimationController _animationController;
  late Animation<double> _animation;
  late List<Map<String, dynamic>> aggregatedList;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300)
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    _animationController.forward();
    aggregatedList=aggregateSingleDonationItemFromDonations(widget.statisticsData);
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                              "Campaign Progress",
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
                                child: Text((((widget.amountRaised / widget.goal) * 100) >= 100) ? "Completed" :
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
                                  "Raised",
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  "\$${formatAmount(widget.amountRaised)}",
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
                                  "Goal",
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  "\$${formatAmount(widget.goal)}",
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )

                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                Divider(color: Colors.grey.shade400),

                Text(
                  "Description",
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
                  "Donation Breakdown",
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
                  "Donation Item Details",
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
                SizedBox(height: 16.0), // Better spacing
                Container(
                  height: MediaQuery.of(context).size.height * .4, // Slightly larger height for better scroll visibility
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade400.withOpacity(0.5), // Light teal background for the list
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: widget.statisticsData.isEmpty ?  Center(child: Text("No Donations!",style: TextStyle(fontSize: 22,color: Colors.grey.shade600,fontWeight: FontWeight.bold),),) : ListView.separated(
                    separatorBuilder: (context, index) => Divider(color: Colors.teal.shade100),
                    itemCount: widget.statisticsData.length,
                    itemBuilder: (context, index) {
                      final item = widget.statisticsData[index];
                      return Card(
                        elevation: 3.0, // Subtle shadow for better separation
                        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        color: Colors.teal.shade50, // Teal-shaded background for the card
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24.0, // Larger size for a more prominent look
                                backgroundColor: Colors.teal.shade700,
                                child: Text(
                                  item['username'][0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.0),
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
                                      maxLines: 2, // Ensure it doesn't overflow
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.0),
                              Text(
                                "\$${item['amount']}",
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
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



class DonationBarChart extends StatefulWidget {
  final List<Map<String, dynamic>> data; // Aggregated donation data
  final double minY;
  final double maxY;
  final AnimationController animationController;
  final Animation<double> animation;
  final Duration duration;
  final bool showBarTouchData;
  final double height;
  final double width;

  DonationBarChart({
    super.key,
    required this.data,
    required this.minY,
    required this.maxY,
    required this.animationController,
    required this.animation,
    required this.duration,
    required this.showBarTouchData,
    required this.height,
    required this.width,
  });

  @override
  State<DonationBarChart> createState() => _DonationBarChartState();
}

class _DonationBarChartState extends State<DonationBarChart> {
  late List<Map<String, dynamic>> chartData;

  @override
  void initState() {
    super.initState();
    chartData = widget.data;
  }

  /// Convert `charts.Color` to Flutter's `Color`
  Color formatColor(dynamic color) {
    if (color is charts.Color) {
      return Color.fromARGB(color.a, color.r, color.g, color.b);
    }
    return Colors.grey; // Fallback color
  }

  /// Format double values to two decimal places
  double formatDouble(double value) {
    return double.parse((value).roundToDouble().toStringAsFixed(2));
  }
  double formatToolTipMargin(double dataPercent){
    if(dataPercent<=widget.maxY * .20){
      return (5) * widget.animationController.value;
    }else{
      return (-95) * widget.animationController.value;
    }
  }
  String formatCompactNumber(double value) {
    if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)}B'; // Format as billions
    } else if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M'; // Format as millions
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K'; // Format as thousands
    } else {
      return value.toStringAsFixed(0); // Format as a whole number
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < chartData.length; i++) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Display username
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      color: Colors.teal.shade900.withOpacity(0.7),
                    ),
                    width: MediaQuery.of(context).size.width * .25,
                    height: widget.height,
                    child: Text(
                      chartData[i]['username'] ?? 'Unknown',
                      style: const TextStyle(
                        overflow: TextOverflow.clip,

                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 2),

                  // Display bar chart for the amount
                  SizedBox(
                    height: widget.height,
                    width: widget.width,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: AnimatedBuilder(
                        animation: CurvedAnimation(
                          parent: widget.animationController,
                          curve: Curves.easeInOut,
                        ),
                        builder: (context, child) {
                          return BarChart(
                            BarChartData(
                              gridData: FlGridData(show: false),
                              extraLinesData: ExtraLinesData(extraLinesOnTop: true),
                              borderData: FlBorderData(show: false),
                              titlesData: const FlTitlesData(
                                show: true,
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              maxY: widget.maxY,
                              minY: widget.minY,
                              barTouchData: BarTouchData(
                                enabled: true, // Change this according to your needs
                                allowTouchBarBackDraw: true,

                                touchTooltipData: BarTouchTooltipData(
                                  tooltipRoundedRadius: 20,
                                  rotateAngle: -90,
                                  tooltipPadding: const EdgeInsets.only(right: 5, left: 5, top: 5),
                                  tooltipMargin: formatToolTipMargin(formatDouble(chartData[i]['amount'] * widget.animationController.value)),
                                ),

                              ),
                              barGroups: [
                                BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: formatDouble(
                                        chartData[i]['amount'] *
                                            widget.animationController.value,
                                      ),
                                      width: widget.height,
                                      color: formatColor(chartData[i]['color']),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                    ),
                                  ],
                                  showingTooltipIndicators: [0],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Add spacing between bars
            ],
          ],
        );
      },
    );
  }
}
