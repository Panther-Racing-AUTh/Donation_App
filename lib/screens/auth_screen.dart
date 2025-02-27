
// Sign In Page
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:donation_app_v1/auth_service.dart';
import 'package:donation_app_v1/const_values/auth_page_values.dart';
import 'package:donation_app_v1/const_values/title_values.dart';
import 'package:donation_app_v1/enums/language_enum.dart';
import 'package:donation_app_v1/icons/donation_icons_icons.dart';
import 'package:donation_app_v1/models/profile_model.dart';
import 'package:donation_app_v1/models/settings_model.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:donation_app_v1/screens/lock_screen.dart';
import 'package:donation_app_v1/screens/welcome_digit_code.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInPage extends StatefulWidget {
  bool isForgotPasscode;
  SignInPage({Key? key,this.isForgotPasscode = false}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  bool authenticated = false;
  String code ="";
  bool _isLoading = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initializeConnectionCheck();
  }

  /// Function to check internet connectivity
  Future<void> _initializeConnectionCheck() async {
    bool isConnected = await isConnectedToWiFi();
    setState(() {
      _isOnline = isConnected;
    });

    if(_isOnline && !widget.isForgotPasscode){
      checkSignedIn();
    }


  }


  /// Periodically check connectivity
  Future<void> _connectionCheck() async {
    bool isConnected = await isConnectedToWiFi();
    setState(() {
      _isOnline = isConnected;
    });

    setState(() {

    });
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

  /// Function to handle sign-in
  Future<void> _signIn() async {
    if (!_isOnline) {
      _showMessage("No Internet Connection");
      _connectionCheck();

      _isLoading = false;
      return; // Prevent sign-in if there's no internet
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _showMessage('Sign In Successful');
        await _fetchProfile();
        final profileProvider=Provider.of<ProfileProvider>(context,listen: false);
        profileProvider.profile!.digit_code.isEmpty ? code = "" : code = profileProvider.profile!.digit_code;
        saveAuthBox(profileProvider.profile!.digit_code);
        if(widget.isForgotPasscode){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LockScreen(isAuthCheck : false,isLockSetup: true),));
        }else{
          code != "" ? Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LockScreen(isAuthCheck : false,isLockSetup: false),)) : Navigator.push(context, MaterialPageRoute(builder: (context) => WelcomeDonationCodePage(),));

        }
      }
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('An unexpected error occurred');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _fetchProfile() async {
    ProfileProvider profileProvider=Provider.of<ProfileProvider>(context,listen: false);
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('uuid', _supabaseClient.auth.currentUser!.id);

      if (response.isNotEmpty) {
        print(response);
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

  void openAuthBox() async {
    // Open the box asynchronously but we don't need a Future return type here
    final authBox = await Hive.openBox<AuthService>('authBox');

    // After the box is opened, check if the user is authenticated
    authenticated = AuthService.isAuthenticated(authBox);
    print('Is authenticated: $authenticated');
  }
  void saveAuthBox(String digitCode) async {
    // Open the box asynchronously but we don't need a Future return type here
    final authBox = await Hive.openBox<AuthService>('authBox');
    AuthService().setNewToken(authBox, digitCode.isNotEmpty && digitCode != "" ? true : false);
    // After the box is opened, check if the user is authenticated
    authenticated = AuthService.isAuthenticated(authBox);
    setState(() {

    });
    print('Is authenticated: $authenticated');
  }

  Future<bool> checkSignedIn() async {
    try {
      // Retrieve the current session
      final session = _supabaseClient.auth.currentSession;

      // Check if a session exists
      if (session != null) {
        print("User is signed in: ${session.user.email}");
        await _fetchProfile();
        final profileProvider = Provider.of<ProfileProvider>(context,listen: false);
        if(profileProvider.profile!.digit_code.isEmpty){
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => WelcomeDonationCodePage(),));
        }else{
          Navigator.pushReplacementNamed(context, '/lock');
        }
        return true;
      } else {
        print("No user is signed in.");
        return false;
      }
    } catch (e) {
      print("Error checking signed-in status: $e");
      return false;
    }
  }

  /// Display a SnackBar message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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


  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 5), () => _connectionCheck());
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(PageTitles.getTitle(getCurrentLanguage(), 'sign_in_title')),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.tealAccent.shade400, Colors.teal.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Wrap(
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            if (!_isOnline)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.wifi_off, color: Colors.red),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AuthLabels.getLabel(getCurrentLanguage(), 'no_internet_connection'),
                                        style: TextStyle(color: Colors.red, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: AuthLabels.getLabel(getCurrentLanguage(), 'email_label_value'),
                                labelStyle: TextStyle(color: Colors.teal.shade800),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.teal.shade800),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.teal.shade800),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.teal.shade800, width: 2.0),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: AuthLabels.getLabel(getCurrentLanguage(), 'password_label_value'),
                                labelStyle: TextStyle(color: Colors.teal.shade800),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.teal.shade800),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.teal.shade800),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.teal.shade800, width: 2.0),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _isOnline ? _signIn : null,
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(AuthLabels.getLabel(getCurrentLanguage(), 'sign_in_button'), style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/signUp');
                              },
                              child: Text(AuthLabels.getLabel(getCurrentLanguage(), 'go_to_register_button')),
                            ),
                            const SizedBox(height: 20),
                            Divider(color: Colors.grey),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      Text(
                        AuthLabels.getLabel(getCurrentLanguage(), 'sign_in_with'),
                        style: TextStyle(color: Colors.grey.shade600.withOpacity(0.7),fontWeight: FontWeight.bold,fontSize: 18),
                      ),
                      const SizedBox(height: 15),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: _isOnline ? () {} : null,
                              icon: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return SweepGradient(
                                    colors: [ Colors.blue, Colors.green, Colors.yellow,Colors.red, Colors.blue, ],
                                    stops: [0.2, 0.3, 0.5, 0.7,1.0], // Positioning colors in the correct order
                                    startAngle: 0,
                                    endAngle: 3.14 * 2, // Full circle
                                  ).createShader(bounds);
                                },
                                child: Icon(DonationIcons.google, color: Colors.white), // White base color
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            IconButton(
                              onPressed: _isOnline ? (){} : null,
                              icon: Icon(DonationIcons.facebook, color: Colors.blue),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _isOnline ? (){} : null,
                              icon: Icon(Icons.apple, color: Colors.black,),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _isOnline ? (){} : null,
                              icon: Icon(DonationIcons.github_circled, color: Colors.black),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _isOnline ? (){} : null,
                              icon: Icon(DonationIcons.linkedin, color: Colors.blue.shade700),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _isOnline ? (){} : null,
                              icon: Icon(DonationIcons.x_8229321_1280, color: Colors.black),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

// Sign Up Page

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  bool _isLoading = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initializeConnectionCheck();
  }

  /// Check internet connectivity at startup
  Future<void> _initializeConnectionCheck() async {
    bool isConnected = await isConnectedToWiFi();
    setState(() {
      _isOnline = isConnected;
    });
  }

  /// Check connectivity periodically
  Future<void> _connectionCheck() async {
    bool isConnected = await isConnectedToWiFi();
    setState(() {
      _isOnline = isConnected;
    });


  }

  /// Check Wi-Fi connectivity
  Future<bool> isConnectedToWiFi() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.mobile) ;
    } catch (e) {
      print('Error checking internet connectivity: $e');
      return false;
    }
  }

  /// Sign up logic
  Future<void> _signUp() async {
    if(!_isOnline){
      _showMessage("No Internet Connection");
      _connectionCheck();
      _isLoading = false;

      return;
    }

    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (validateEmail(email)) {
      try {
        final response = await _supabaseClient.auth.signUp(
          email: email,
          password: password,
          data: {'username': username},
        );
        print("object");
        final response1 = await _supabaseClient.from('profiles').insert({
          'username': username,
          'wallet' : 0,
          'payment_cards' : null,
          'image_url' : null,
          'settings' : {
            "theme": "dark",
            "language": "en",
            "notifications_enabled": false
          },
          'created_at': DateTime.now().toIso8601String(),
        });
        if (response.user != null) {
          _showMessage(
            'Registration Successful. Please check your email for confirmation.',
          );
          _supabaseClient.auth.signOut();
          Navigator.pushReplacementNamed(context, '/signIn');
        }
      } on AuthException catch (e) {
        _showMessage(e.message);
      } catch (e) {
        _showMessage('An unexpected error occurred');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      _showMessage('Invalid email address');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Validate email format and domain
  bool validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return false;
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return false;
    }

    const validDomains = [
      'gmail.com', 'yahoo.com', 'outlook.com', 'example.com',
      'hotmail.com', 'live.com', 'icloud.com', 'aol.com', 'protonmail.com','pantherauth.gr',
      'zoho.com', 'gmx.com', 'yandex.com', 'mail.com', 'me.com', 'fastmail.com',
    ];

    const forbiddenWords = [
      'dummy', 'invalid', 'test', 'noreply', 'spam',
    ];

    final localPart = email.split('@').first.toLowerCase();
    final domain = email.split('@').last;

    if (forbiddenWords.any((word) => localPart.contains(word))) {
      return false;
    }

    return validDomains.contains(domain);
  }

  /// Display a Snackbar message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

  @override
  Widget build(BuildContext context) {
    final profileProvider= Provider.of<ProfileProvider>(context,listen: false);

    Future.delayed(const Duration(seconds: 5), () => _connectionCheck());
    return Scaffold(
      appBar: AppBar(
        title: Text(PageTitles.getTitle(getCurrentLanguage(), 'sign_up_title')),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.tealAccent.shade400, Colors.teal.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Wrap(
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          child: Column(
                            children: [
                              if (!_isOnline)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children:  [
                                      Icon(Icons.wifi_off, color: Colors.red),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          AuthLabels.getLabel(getCurrentLanguage(), 'no_internet_connection'),
                                          style: TextStyle(color: Colors.red, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: AuthLabels.getLabel(getCurrentLanguage(), 'username_label_value'),
                                  labelStyle: TextStyle(color: Colors.teal.shade800),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.teal.shade800),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.teal.shade800),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.teal.shade800, width: 2.0),
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                keyboardType: TextInputType.text,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: AuthLabels.getLabel(getCurrentLanguage(), 'email_label_value'),
                                  labelStyle: TextStyle(color: Colors.teal.shade800),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.teal.shade800),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.teal.shade800),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.teal.shade800, width: 2.0),
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: AuthLabels.getLabel(getCurrentLanguage(), 'password_label_value'),
                                  labelStyle: TextStyle(color: Colors.teal.shade800),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.teal.shade800),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.teal.shade800),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.teal.shade800, width: 2.0),
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    backgroundColor: Colors.grey.shade300,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _isOnline ? _signUp : null,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Text(AuthLabels.getLabel(getCurrentLanguage(), 'sign_up_button'), style: TextStyle(fontSize: 16)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, '/signIn');
                                },
                                child: Text(AuthLabels.getLabel(getCurrentLanguage(), 'go_to_sign_in_button')),
                              ),
                              const SizedBox(height: 20),
                              Divider(color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AuthLabels.getLabel(getCurrentLanguage(), 'sign_up_with'),
                        style: TextStyle(color: Colors.grey.shade600.withOpacity(0.7),fontWeight: FontWeight.bold,fontSize: 18),
                      ),
                      const SizedBox(height: 15),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: _isOnline ? () {} : null,
                              icon: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return SweepGradient(
                                    colors: [ Colors.blue, Colors.green, Colors.yellow,Colors.red, Colors.blue, ],
                                    stops: [0.2, 0.3, 0.5, 0.7,1.0], // Positioning colors in the correct order
                                    startAngle: 0,
                                    endAngle: 3.14 * 2, // Full circle
                                  ).createShader(bounds);
                                },
                                child: Icon(DonationIcons.google, color: Colors.white), // White base color
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            IconButton(
                              onPressed: _isOnline ? (){} : null,
                              icon: Icon(DonationIcons.facebook, color: Colors.blue),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _isOnline ? (){} : null,
                              icon: Icon(Icons.apple, color: Colors.black),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _isOnline ? (){} : null,
                              icon: Icon(DonationIcons.github_circled, color: Colors.black),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _isOnline ? (){} : null,
                              icon: Icon(DonationIcons.linkedin, color: Colors.blue.shade700),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _isOnline ? (){} : null,
                              icon: Icon(DonationIcons.x_8229321_1280, color: Colors.black),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient gradient;

  const GradientIcon(this.icon, {Key? key, required this.size, required this.gradient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return gradient.createShader(bounds);
      },
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}