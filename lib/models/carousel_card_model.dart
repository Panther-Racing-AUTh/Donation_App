
import 'dart:async';

import 'package:donation_app_v1/screens/donation_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CarouselCard extends StatefulWidget {
  final int id;
  final String imagePath;
  final String title;
  final int amount;
  final int goal;
  final String description;
  final List<Map<String, dynamic>> statisticsData;
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
    required this.isActive,
  }) : super(key: key);

  @override
  _CarouselCardState createState() => _CarouselCardState();
}

class _CarouselCardState extends State<CarouselCard> {
  final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client

  late Duration remainingTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
            _updateDonationItem(widget.id, {'is_active': false});
            timer.cancel();
          }
        });
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _updateDonationItem(int id, Map<String, dynamic> updatedValues) async {
    try {
      // Replace `_supabaseClient` with your actual database client
      await _supabaseClient.from('donation_items').update(updatedValues).eq('id', id);
    } catch (e) {
      _showMessage('An unexpected error occurred: $e');
    }
  }

  Duration _calculateRemainingDuration(String timestamp) {
    try {
      final DateTime targetTime = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();
      final Duration remainingDuration = targetTime.difference(now);
      return remainingDuration.isNegative ? Duration.zero : remainingDuration;
    } catch (e) {
      debugPrint('Error parsing timestamp: $e');
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
      double result = amount / 1000000;
      return '${result.toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      double result = amount / 1000;
      return '${result.toStringAsFixed(1)}k';
    } else {
      return amount.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debugging title here

    bool goalAchieved = widget.amount >= widget.goal;

    // Ensure title has a fallback value
    final title = widget.title.isNotEmpty ? widget.title : 'Donation Item';

    return GestureDetector(
      onTap: widget.isActive
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DonationStatisticsPage(
              id: widget.id,
              pic: widget.imagePath,
              title: widget.title.isNotEmpty ? widget.title : 'Donation Item',
              amountRaised: widget.amount,
              goal: widget.goal,
              description: widget.description,
              isActive: widget.isActive,
              timerDuration: widget.timerDuration,
              statisticsData: widget.statisticsData,
            ),
          ),
        );
      }
          : null,
      child: Container(
        height: 220,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                padding: EdgeInsets.all(10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (widget.isActive || goalAchieved)
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: widget.amount / widget.goal,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatAmount(widget.amount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatAmount(widget.goal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (widget.isActive)
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
            if (!widget.isActive)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Inactive',
                    style: const TextStyle(
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
