import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'widgets/auth/auth_wrapper.dart';

// Global logger instance
final logger = Logger(
  printer: PrettyPrinter(
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i('Firebase initialized successfully');
  } catch (e, stackTrace) {
    logger
      ..e(
        'Firebase initialization failed',
        error: e,
        stackTrace: stackTrace,
      )
      ..w('Continuing app startup despite Firebase initialization failure');

    // In a production app, you might want to:
    // 1. Show an error dialog to the user
    // 2. Prevent the app from continuing
    // 3. Send crash reports to a service like Firebase Crashlytics

    // For now, we'll continue but the app might not work properly
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => BookingProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sport Centre Booking',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
