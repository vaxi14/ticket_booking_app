import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ticket_booking_app/firebase_options.dart';
import 'package:ticket_booking_app/screens/home_screen.dart';
import 'package:ticket_booking_app/screens/login_screen.dart';
import 'package:ticket_booking_app/screens/profile_screen.dart';
import 'package:ticket_booking_app/screens/user_detail_screen.dart';
import 'package:ticket_booking_app/screens/help_support_screen.dart';
import 'package:ticket_booking_app/services/firestore_service.dart';
import 'package:ticket_booking_app/services/notification_service.dart';

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await setupFCM();

  // Initialize Stripe
  Stripe.publishableKey = "pk_test_51Qxn0BFxEBWdDqJ6bFeR4BidcihaXOql31VHdzVz3FKJg9Fxm0Dv66kppJkfP3MMiqaS4HEtyfSMCrpYGZUdIlWn00jFZI1B1Z";
  await Stripe.instance.applySettings();

  // Initialize Local Notifications
  await NotificationService.initialize();

  runApp(const MyApp());
}

/// Function to set up FCM (Firebase Cloud Messaging)
Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission for notifications
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("✅ User granted permission for notifications");
  } else {
    print("🚫 User denied permission");
    return;
  }

  // Get FCM Token
  String? token = await messaging.getToken();
  print("🔑 FCM Token: $token");

  // Store FCM token in Firestore if user is logged in
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null && token != null) {
    await FirestoreService().saveFCMToken(user.uid, token);
  }

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Received a foreground notification: ${message.notification?.title}");
    NotificationService.showNotification(message);
  });

  // Handle notification taps when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📲 User tapped on notification: ${message.notification?.title}");
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticket Booking App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/login' : '/home',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/user-details': (context) => UserDetailsScreen(userData: {}),
        '/help': (context) => HelpSupportScreen(),
      },
    );
  }
}
