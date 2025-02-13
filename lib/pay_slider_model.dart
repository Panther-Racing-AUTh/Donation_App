import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PayPage extends StatefulWidget {
  final double amount;

   PayPage({super.key,required this.amount});

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background color for the screen
      body: SafeArea( // To avoid screen cut-off for devices with notches
        child: Center(
          child: Stack(
            children: [
              // Title text above the slider
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title Section with a background container
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100, // Soft background color
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8.0,
                            offset: Offset(0, 4), // Shadow below the container
                          ),
                        ],
                      ),
                      child: Text(
                        'Complete Your Payment',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800, // Text color to complement background
                        ),
                      ),
                    ),

                    // Padding and Information Text Section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200, // Light grey background
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6.0,
                              offset: Offset(0, 2), // Slight shadow
                            ),
                          ],
                        ),
                        child: Text(
                          'You are about to pay ${widget.amount.toStringAsFixed(0)} \$',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700, // Dark grey text
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Slide to action widget
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SlideToActionWidget(
                    actionText: 'Slide to Pay ${widget.amount} \$',
                    amount: 1000,
                    backgroundColor: Colors.grey.shade700,
                    sliderColor: Colors.teal,
                    textColor: Colors.white,
                    onActionComplete: () {
                      // Callback when sliding action completes
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Payment Successful'),
                          content: Text('You have successfully paid ₹255!'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
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
        ),
      ),
    );
  }
}


class SlideToActionWidget extends StatefulWidget {
  final String actionText;
  final Color backgroundColor;
  final Color sliderColor;
  final Color textColor;
  final double amount;
  final VoidCallback onActionComplete;

  const SlideToActionWidget({
    required this.actionText,
    required this.onActionComplete,
    required this.amount,
    this.backgroundColor = Colors.grey,
    this.sliderColor = Colors.teal,
    this.textColor = Colors.white,
    Key? key,
  }) : super(key: key);

  @override
  _SlideToActionWidgetState createState() => _SlideToActionWidgetState();
}

class _SlideToActionWidgetState extends State<SlideToActionWidget> {
  double _sliderPosition = 0.0;
  bool _actionCompleted = false;
  bool _iconDisplayed=false;

  late double containerWidth;
  final double buttonWidth = 70.0; // Width of the sliding button
  late double maxSliderPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to use MediaQuery here
    containerWidth = MediaQuery.of(context).size.width - 32;
    maxSliderPosition = containerWidth - buttonWidth;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      onEnd: () {
        setState(() {
          if(_actionCompleted){
            _iconDisplayed=true;
            Future.delayed(Duration(milliseconds: 1500)).whenComplete(() => widget.onActionComplete(),);
            Future.delayed(Duration(milliseconds: 3500)).whenComplete(() {
              _iconDisplayed=false;
              _actionCompleted=false;
              containerWidth = MediaQuery.of(context).size.width - 32;
              _sliderPosition=0.0;
              setState(() {

              });
            },);

          }
        });
      },
      height: 70,
      width: containerWidth,
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Sliding text
          Center(
            child: _iconDisplayed ?           Lottie.asset('assets/check_slider_bright.json',repeat: false) : Text(
              _actionCompleted ? '' : "Slide to Pay",
              style: TextStyle(
                fontSize: 25,
                color: _sliderPosition > maxSliderPosition / 2
                    ? widget.textColor
                    : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if(!_actionCompleted)...[
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: AnimatedContainer(
                color: widget.backgroundColor,
                margin: EdgeInsets.only(left: 35),
                width: _sliderPosition + 30,
                duration: Duration(milliseconds: 100),
              ),
            ),
          ],
          // Sliding button
          AnimatedPositioned(
            duration: Duration(milliseconds: 150),
            left: _sliderPosition,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _sliderPosition += details.primaryDelta!;
                  _sliderPosition = _sliderPosition.clamp(0.0, maxSliderPosition);
                });
              },
              onHorizontalDragEnd: (details) {
                if (_sliderPosition >= maxSliderPosition * 0.95) {
                  setState(() {
                    _actionCompleted = true;
                    _sliderPosition = maxSliderPosition;
                    containerWidth= 70;
                  });
                } else {
                  setState(() {
                    _sliderPosition = 0.0;
                    containerWidth = MediaQuery.of(context).size.width - 32;

                  });
                }
              },
              child: Container(
                height: 64,
                width: buttonWidth,
                decoration: BoxDecoration(
                  color: widget.sliderColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
