import 'package:flutter/material.dart';

class MakeButton extends StatelessWidget{
  final String text;
  final Color primaryColor;
  final Color secondaryColor;
  final double widthLength;
  final double heightLength;
  final double borderRadiusSize;
  final Widget widget;

  VoidCallback onPressed;

  MakeButton({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.text,
    required this.heightLength,
    required this.widthLength,
    required this.onPressed,
    required this.widget,
    this.borderRadiusSize=10
  });

  @override
  Widget build(BuildContext context){
    return SizedBox(
      width: widthLength,
      height: heightLength,
      child: MaterialButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSize),
        
        ),
        onPressed: onPressed,
        color: secondaryColor,
        child: widget,
      ),
    );
  }

}
