import 'dart:math';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:donation_app_v1/notification_functions.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:donation_app_v1/screens/about_us_screen.dart';
import 'package:donation_app_v1/auth.dart';
import 'package:donation_app_v1/screens/donations_screen.dart';
import 'package:donation_app_v1/screens/feedback_screen.dart';
import 'package:donation_app_v1/screens/profile_screen.dart';
import 'package:donation_app_v1/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    // You can add iOS settings here if needed.
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await Supabase.initialize(
    url: 'https://zmowwytgkbchbejxggac.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inptb3d3eXRna2JjaGJlanhnZ2FjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzIwMjQ5NTcsImV4cCI6MjA0NzYwMDk1N30.wwXOJUldI8MhDlNrJboKJqR3z1otrZXIXo0c1a-KbKU',
  );
  runApp(const MyApp());
  // Schedule a one-time notification in the background

}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    requestNotificationPermission(); // Request permission at startup
    requestGalleryPermission();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(),
        ),
        // Add other providers here if needed
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Authentication Demo',
        home: const SignInPage(),
        routes: {
          '/signIn': (_) =>  SignInPage(),
          '/signUp': (_) =>  SignUpPage(),
          '/donation': (_) => DonationsPage(),
          '/aboutUs': (_) => AboutUsPage(),
          '/profile': (_) => ProfilePage(isTopDonator: false),
          '/feedback': (_) => FeedbackScreen(),
          '/settings': (_) => SettingsPage(),
        },
      ),
    );
  }
}


