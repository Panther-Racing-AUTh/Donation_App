
// Sign In Page
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:donation_app_v1/const_values/title_values.dart';
import 'package:donation_app_v1/models/profile_model.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
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

  /// Function to check internet connectivity
  Future<void> _initializeConnectionCheck() async {
    bool isConnected = await isConnectedToWiFi();
    setState(() {
      _isOnline = isConnected;
    });

    if(_isOnline){
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
        Navigator.pushReplacementNamed(context, '/donation');
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
          .eq('username', _supabaseClient.auth.currentUser!.userMetadata!['username']);

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

  Future<bool> checkSignedIn() async {
    try {
      // Retrieve the current session
      final session = _supabaseClient.auth.currentSession;

      // Check if a session exists
      if (session != null) {
        print("User is signed in: ${session.user.email}");
        await _fetchProfile();
        Navigator.pushReplacementNamed(context, '/donation');
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


  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 5), () => _connectionCheck());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
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
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.wifi_off, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No Internet Connection. Please check your connection.',
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
                      labelText: 'Email',
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
                      labelText: 'Password',
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
                          : const Text('Sign In', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signUp');
                    },
                    child: const Text("Don't have an account? Register"),
                  ),
                ],
              ),
            ),
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
        final response1 = await _supabaseClient.from('profiles').insert({
          'username': username,
          'wallet' : 0,
          'payment_cards' : [],
          'image_url' : '',
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

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 5), () => _connectionCheck());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
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
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.wifi_off, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No Internet Connection. Please check your connection.',
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
                      labelText: 'Username',
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
                      labelText: 'Email',
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
                      labelText: 'Password',
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
                          : const Text('Register', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signIn');
                    },
                    child: const Text("Do you have an account? Sign in"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

