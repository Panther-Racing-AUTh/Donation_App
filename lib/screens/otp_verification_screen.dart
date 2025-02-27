
import 'package:donation_app_v1/models/button_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPForm extends StatefulWidget {
  const OTPForm({super.key});

  @override
  State<OTPForm> createState() => _OTPFormState();
}

class _OTPFormState extends State<OTPForm> {
  late String phoneNumber;
  late String formattedPhoneNumber;
  late List code;
  late List _otpController;
  late Color primaryColor;
  late Color secondaryColor;

  @override
  void initState(){
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
      SystemUiOverlay.top,
      SystemUiOverlay.bottom
    ]);
    _otpController =[
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ]; // Create a TextEditingController

    primaryColor=Colors.black;
    secondaryColor=Colors.black;

    code=List.generate(4, (index) => int);
    phoneNumber="+306974995625";
    formattedPhoneNumber=makeInvisiblePhoneNumber(phoneNumber);
  }

  String makeInvisiblePhoneNumber(String phoneNumber){
    String tempPhoneNum=phoneNumber;
    for(int i=3;i<phoneNumber.length-4;i++){
      tempPhoneNum=tempPhoneNum.replaceRange(i, i+1, '*');
    }
    print(tempPhoneNum);
    return tempPhoneNum;
  }



  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top + 56, // Height for the back button
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.top + 100, // Height for the back button
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 70,
                      width: 64,
                      child: TextField(
                        controller: _otpController[0],
                        autofocus: true,
                        onChanged: (value) {
                          code[0]=_otpController[0].text;
                          if(value.length==1){
                            FocusScope.of(context).nextFocus();
                          }
                        },
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
                          color: Colors.black,
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)),),
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 70,
                      width: 64,
                      child: TextField(
                        controller: _otpController[1],
                        onChanged: (value) {
                          code[1]=_otpController[1].text;
                          if(value.length==1){
                            FocusScope.of(context).nextFocus();
                          }
                          if (value.isEmpty) {
                            FocusScope.of(context).previousFocus();

                          }
                        },
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
                          color: Colors.black,
                          // Other properties such as color, letterSpacing, etc.
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)),),
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 70,
                      width: 64,
                      child: TextField(
                        controller: _otpController[2],
                        onChanged: (value) {
                          code[2]=_otpController[2].text;
                          if(value.length==1){
                            FocusScope.of(context).nextFocus();
                          }
                          if (value.isEmpty) {
                            FocusScope.of(context).previousFocus();

                          }

                        },
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
                          color: Colors.black,
                          // Other properties such as color, letterSpacing, etc.
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)),),
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 70,
                      width: 64,
                      child: TextField(
                        controller: _otpController[3],
                        onChanged: (value) {
                          code[3]=_otpController[3].text;
                          if(value.length==1){
                            FocusScope.of(context).nextFocus();
                          }
                          if (value.isEmpty) {
                            FocusScope.of(context).previousFocus();

                          }
                        },
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
                          color: Colors.black,
                          // Other properties such as color, letterSpacing, etc.
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)),),
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MakeButton(widget: Text("Cancel",style: TextStyle(fontSize: 18),), onPressed: (){},primaryColor: Colors.purple,secondaryColor: Colors.deepPurple,heightLength: 60,widthLength: 150,borderRadiusSize: 15, text: '',),
                    const SizedBox(width: 100,),
                    MakeButton(widget: Icon(Icons.arrow_forward,size: 27,fill: BorderSide.strokeAlignCenter,), onPressed: (){
                      print(code);
                    },primaryColor: Colors.purple,secondaryColor: Colors.deepPurple,heightLength: 60,widthLength: 60,borderRadiusSize: 60, text: '',),



                  ],
                ),
              )
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 15,
            left: 8.0,
            child: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop(); // Navigate back when the button is pressed
              },
            ),
          ),
          Positioned(
              top: MediaQuery.of(context).padding.top + 75,
              left: 22.0,
              child: Text("Verification Code",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700

                ),)
          ),
          Positioned(
              top: MediaQuery.of(context).padding.top + 120,
              left: 27.0,
              child: const Text("We have sent the code verification to",
                style: TextStyle(
                    color: Colors.deepPurple,
                    fontSize: 13,
                    fontWeight: FontWeight.w400

                ),)
          ),
          Positioned(
              top: MediaQuery.of(context).padding.top + 126,
              left: 27.0,
              child: Row(
                children: [
                  Text("$formattedPhoneNumber",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w800

                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: TextButton(
                      onPressed: (){

                      },
                      style: ButtonStyle(
                        overlayColor: MaterialStateColor.resolveWith((states) => Colors.transparent),

                      ),
                      child: Text(
                        "Change phone number?",
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )

                ],
              )
          ),

        ],
      ),
    );
  }
}



