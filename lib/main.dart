import 'dart:math';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:donation_app_v1/auth_service.dart';
import 'package:donation_app_v1/models/settings_model.dart';
import 'package:donation_app_v1/notification_functions.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:donation_app_v1/screens/about_us_screen.dart';
import 'package:donation_app_v1/screens/auth_screen.dart';
import 'package:donation_app_v1/screens/donations_screen.dart';
import 'package:donation_app_v1/screens/feedback_screen.dart';
import 'package:donation_app_v1/screens/lock_screen.dart';
import 'package:donation_app_v1/screens/profile_screen.dart';
import 'package:donation_app_v1/screens/settings_screen.dart';
import 'package:donation_app_v1/screens/welcome_digit_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    // You can add iOS settings here if needed.
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await Hive.initFlutter();
  Hive.registerAdapter(SettingsAdapter());
  await Hive.openBox<Settings>('settingsBox');
  await Hive.openBox<AuthService>('authBox');

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
  bool authenticated = false;
  bool checkOnce=false;

  @override
  void initState() {
    super.initState();
    requestNotificationPermission(); // Request permission at startup
    requestGalleryPermission();
    openAuthBox();
  }

  // Function to fetch the digit_code from Supabase and set authentication status
  void openAuthBox() async {
    // Open the box asynchronously but we don't need a Future return type here
    final authBox = await Hive.openBox<AuthService>('authBox');

    // After the box is opened, check if the user is authenticated
    authenticated = AuthService.isAuthenticated(authBox);
    print('Is authenticated: $authenticated');
  }
  @override
  Widget build(BuildContext context) {
    // Call checkAuthStatus only when the ProfileProvider is available


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
        home: SignInPage(),

        routes: {
          '/lock': (_) => LockScreen(isAuthCheck: false,isLockSetup: false),
          '/signIn': (_) => SignInPage(),
          '/signUp': (_) => SignUpPage(),
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


