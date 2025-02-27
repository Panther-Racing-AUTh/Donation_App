import 'dart:io';

import 'package:donation_app_v1/auth_service.dart';
import 'package:donation_app_v1/const_values/lock_page_values.dart';
import 'package:donation_app_v1/models/light_dark_model.dart';
import 'package:donation_app_v1/models/loading_overlay.dart';
import 'package:donation_app_v1/models/settings_model.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:donation_app_v1/screens/auth_screen.dart';
import 'package:donation_app_v1/screens/donations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';

final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client

class LockScreen extends StatefulWidget{
  bool isAuthCheck;
  bool isLockSetup;
  LockScreen({super.key,required this.isAuthCheck,required this.isLockSetup});

  @override
  _LockScreen createState() => _LockScreen();

}

class _LockScreen extends State<LockScreen>{
  late ProfileProvider profileProvider=Provider.of<ProfileProvider>(context, listen: false);
  

  final int numLockPins=6;
  bool authenticated=false;
  final List nums=[1,2,3,4,5,6,7,8,9,0];
  String inputText="";
  String tempCode = "";
  bool verifyStep = false; // To track verification step

  var actives;
  var clears;
  var values;
  var currentIndex=0;
  String code="";
  bool _loading=false;



  @override
  void initState(){

    setState(() {

      actives=List.generate(numLockPins, (index) => false, growable: false);
      clears=List.generate(numLockPins, (index) => false, growable: false);
      values=setValues(numLockPins);
      fetchDigitCode(context);
    });
    super.initState();
  }
  String getCurrentLanguage()  {
    // Ensure that the Hive box is open. If already open, this returns the box immediately.
    final Box<Settings> settingsBox = Hive.box<Settings>('settingsBox');

    // Retrieve stored settings or use default settings if none are stored.
    final Settings settings = settingsBox.get('userSettings', defaultValue: Settings.defaultSettings)!;

    // Return the current language as an enum.
    return  settings.language;
  }
  String getCurrentTheme()  {
    // Ensure that the Hive box is open. If already open, this returns the box immediately.
    final Box<Settings> settingsBox = Hive.box<Settings>('settingsBox');

    // Retrieve stored settings or use default settings if none are stored.
    final Settings settings = settingsBox.get('userSettings', defaultValue: Settings.defaultSettings)!;

    // Return the current language as an enum.
    return  settings.theme;
  }

  Future<void> updateDigitCode(String digitCode) async {
    final profileProvider = Provider.of<ProfileProvider>(context,listen: false);
    try {
      final response = await _supabaseClient
          .from('profiles') // Replace with your table name
          .update({
        'digit_code': digitCode, // Column to update
      }).eq('uuid', _supabaseClient.auth.currentUser!.id);

      if (response.error != null) {
        print('Error: ${response.error!.message}');
      } else {
        print('Successfully updated the email');
      }
    } catch (e) {
      print('Error updating column: $e');
    }
  }

  void saveAuthBox(bool newToken) async {
    // Open the box asynchronously but we don't need a Future return type here
    final authBox = await Hive.openBox<AuthService>('authBox');

    // After the box is opened, check if the user is authenticated
    AuthService().saveToken(authBox, newToken);
    authenticated = AuthService.isAuthenticated(authBox);

    print('Is authenticated: $authenticated');
  }


  void fetchDigitCode(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    _supabaseClient
        .from('profiles') // Replace with your table name
        .select('digit_code') // Specify the column to select
        .eq('id', profileProvider.profile!.id)
        .single()
        .then((response) {
      if (response.isEmpty) {
        print('Error: $response');
        code = "";
      } else {
        code = response['digit_code'] as String;
        setState(() {

        });
        print(code);
      }
    }).catchError((e) {
      print('Error fetching digit code: $e');
      code = "";
    });
  }
  String setPinCode(int numLockPins){
    String tempCode="";
    for(int i=0;i<numLockPins;i++){
      tempCode+=(i+1).toString();
    }
    return tempCode;
  }

  List setValues(int numLockPins){
    int temp=1;
    List tempList=[];
    if(numLockPins.isEven){
      for(int i=0;i<numLockPins/2;i++){
        tempList.add(i+1);
      }
      for(int i=(numLockPins/2).round();i<numLockPins;i++){
        tempList.add(numLockPins-i);
      }
    }else if(numLockPins.isOdd){
      for(int i=0;i<(numLockPins/2).ceil();i++){
        tempList.add(i+1);
      }
      for(int i=(numLockPins.ceil());i<numLockPins;i++){
        tempList.add(numLockPins - i);
      }
    }
    return tempList;
  }

  bool isCodeCorrect(String inputText, String code) {
    if (inputText.length != code.length) {
      print('Length mismatch: InputText (${inputText.length}) vs Code (${code.length})');
      print(inputText);
      print(code);
      return false;
    }

    for (int i = 0; i < inputText.length; i++) {
      if (inputText[i] != code[i]) {
        print('Mismatch at index $i: Input (${inputText[i]}) vs Code (${code[i]})');
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: ThemeModel.getListThemeColors(getCurrentTheme(), 'lockScaffoldBackgroundColor'),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(
                height: 100,
              ),
              if (widget.isLockSetup) ...[
                Text(
                  verifyStep
                      ? LockLabels.getLabel(getCurrentLanguage(), 'reenter_new_password')
                      : LockLabels.getLabel(getCurrentLanguage(), 'enter_new_password'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ] else ...[
                Text(
                  LockLabels.getLabel(getCurrentLanguage(), 'enter_password'),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],

              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10,top: 10),
                    height: 160,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < numLockPins; i++)
                          AnimationBoxItem(
                            clear: clears[i],
                            active: actives[i],
                            value: values[i],
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                flex: 3,
                child: Container(
                  margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * .05),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: .7 / .6,
                    ),
                    itemBuilder: (context, index) => Container(
                      color: Colors.transparent,
                      margin: const EdgeInsets.all(8.0),
                      width: 50,
                      height: 50,
                      child: index == 9
                          ? const SizedBox()
                          : Center(
                        child: MaterialButton(
                          minWidth: 50,
                          height: 55,
                          onPressed: () {
                            HapticFeedback.vibrate();

                            if (index == 11) {
                              // Backspace action
                              if (currentIndex > 0) {
                                setState(() {
                                  inputText = inputText.substring(
                                      0, inputText.length - 1);
                                  currentIndex--;
                                  clears[currentIndex] = false;
                                  actives[currentIndex] = false;
                                });
                              }
                            } else {
                              // Add digit to inputText
                              if (inputText.length < 6) {
                                setState(() {
                                  actives[currentIndex] = true;
                                  currentIndex++;
                                });
                              }
                              inputText += nums[index == 10 ? index - 1 : index]
                                  .toString();
                            }

                            if (inputText.length == numLockPins) {
                              if (widget.isLockSetup) {
                                if (verifyStep) {
                                  // Verify step
                                  if (inputText == tempCode) {
                                    setState(() {
                                      code = inputText;
                                      updateDigitCode(code);
                                      profileProvider.updateIsLocked(false);
                                      saveAuthBox(true);
                                      _loading = true;
                                    });

                                    Future.delayed(
                                        const Duration(milliseconds: 1800),
                                            () {
                                          setState(() {
                                            _loading = false;
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => DonationsPage(),
                                              ),
                                            );
                                          });
                                        });
                                  } else {
                                    setState(() {
                                      clears =
                                          clears.map((e) => true).toList();
                                      actives =
                                          actives.map((e) => false).toList();
                                      inputText = "";
                                      currentIndex = 0;
                                      verifyStep = false;
                                    });
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "Passwords do not match. Try again."),
                                      ),
                                    );
                                  }
                                } else {
                                  // First input step
                                  setState(() {
                                    tempCode = inputText;
                                    inputText = "";
                                    currentIndex = 0;
                                    clears = clears.map((e) => true).toList();
                                    actives = actives.map((e) => false).toList();
                                    verifyStep = true;
                                  });
                                }
                              } else {
                                // Normal password check
                                if (isCodeCorrect(inputText, code)) {
                                  setState(() {
                                    profileProvider.updateIsLocked(false);
                                    _loading = true;
                                  });

                                  Future.delayed(
                                      const Duration(milliseconds: 1800), () {
                                    setState(() {
                                      _loading = false;
                                      widget.isAuthCheck ? Navigator.pop(context,true) : Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DonationsPage(),
                                        ),
                                      );
                                    });
                                  });
                                } else {
                                  Vibration.vibrate(duration: 600);
                                }
                              }

                              setState(() {
                                clears = clears.map((e) => true).toList();
                                actives = actives.map((e) => false).toList();
                                inputText = "";
                                currentIndex = 0;
                              });
                            }

                            clears = clears.map((e) => false).toList();
                          },
                          hoverColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          splashColor: (currentIndex == 0 && index == 11) ? Colors.transparent : ThemeModel.getThemeColors(getCurrentTheme(),'lockButtonSplashColor'),

                          highlightElevation: (currentIndex == 0 && index == 11) ? 0 : 5,
                          elevation: (currentIndex == 0 && index == 11) ? 0 : 6,
                          color: (currentIndex == 0 && index == 11) ? Colors.transparent : ThemeModel.getThemeColors(getCurrentTheme(),'lockButtonColor') ,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: index == 11
                              ?  (currentIndex > 0) ?  Icon(
                            Icons.backspace_rounded,
                            color: ThemeModel.getThemeColors(getCurrentTheme(),'lockButtonTextColor'),
                          ) : null
                              : Text(
                            "${nums[index == 10 ? index - 1 : index]}",
                            style:  TextStyle(
                              color: ThemeModel.getThemeColors(getCurrentTheme(),'lockButtonTextColor'),
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    itemCount: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignInPage(isForgotPasscode: true),
                    ),
                  );
                },
                child: Text(
                  LockLabels.getLabel(getCurrentLanguage(), 'forgot_passcode'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // Adjust the font size as needed
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

}

class AnimationBoxItem extends StatefulWidget {
  final clear;
  final active;
  final value;

  AnimationBoxItem({super.key,this.clear=false,this.active=false,this.value}) ;

  @override
  State<AnimationBoxItem> createState() => _AnimationBoxItemState();
}

class _AnimationBoxItemState extends State<AnimationBoxItem> with TickerProviderStateMixin{
  late AnimationController animationController;

  @override
  void initState(){
    super.initState();
    animationController =AnimationController(vsync: this,duration: Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    animationController.dispose(); // Dispose the animation controller properly
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(widget.clear){
      animationController.forward(from: 0);
    }
    return AnimatedBuilder(
        animation: animationController,
        builder: (context,child) => Container(
          margin: widget.active ? EdgeInsets.symmetric(horizontal: 5.0) :EdgeInsets.symmetric(horizontal: 8.0,vertical: 6),
          //color: Colors.red,
          child: Stack(
            children: [
              Container(),
              AnimatedContainer(
                duration: Duration(milliseconds: 800),
                width: widget.active ? 20 : 10,
                height: widget.active ? 20 : 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.active ? Colors.green : Colors.grey

                ),

              ),
              Align(
                alignment: Alignment(0,animationController.value/widget.value-1),
                child: Opacity(
                  opacity: 1-animationController.value,
                  child: Container(
                    width: widget.active ? 20 : 10,
                    height: widget.active ? 20 : 10,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.active ? Colors.green : Colors.grey

                    ),

                  ),
                ),

              ),
            ],
          ),
        )
    );
  }
}


