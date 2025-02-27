
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

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
