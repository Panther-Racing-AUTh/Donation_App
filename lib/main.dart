import 'dart:math';

import 'package:donation_app_v1/about_us_screen.dart';
import 'package:donation_app_v1/auth.dart';
import 'package:donation_app_v1/donations_screen.dart';
import 'package:donation_app_v1/feedback_screen.dart';
import 'package:donation_app_v1/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zmowwytgkbchbejxggac.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inptb3d3eXRna2JjaGJlanhnZ2FjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzIwMjQ5NTcsImV4cCI6MjA0NzYwMDk1N30.wwXOJUldI8MhDlNrJboKJqR3z1otrZXIXo0c1a-KbKU',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Authentication Demo',
      home:  SignInPage(),
      routes: {
        '/signIn': (_) =>  SignInPage(),
        '/signUp': (_) =>  SignUpPage(),
        '/donation' : (_) => DonationsPage(),
        '/aboutUs' : (_) => AboutUsPage(),
        '/profile' : (_) => ProfilePage(isTopDonator: false,),
        '/feedback' : (_) => FeedbackScreen()
      },
    );
  }
}
