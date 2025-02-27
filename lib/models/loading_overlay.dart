import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingOverlay extends StatefulWidget  {
  final bool isLoading;
  final Widget child;

  LoadingOverlay({required this.isLoading, required this.child});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> with TickerProviderStateMixin{
  late AnimationController _animationController;

  @override
  void initState() {

    _animationController=AnimationController(vsync: this);
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
      }
    });
    super.initState();

  }

    @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child, // Your screen's content
        Visibility(
          visible: widget.isLoading,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Center(
                child: Lottie.asset(
                  'assets/lotties/digit_code_unlock.json',
                  frameRate: FrameRate(20),
                  controller: _animationController,
                  onLoaded: (composition) {
                    _animationController.duration = composition.duration;
                    _animationController.forward();
                    },

                  height: 170,
                  width: 170,

                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}