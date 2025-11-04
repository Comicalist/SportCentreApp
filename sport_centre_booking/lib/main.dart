import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'widgets/auth/auth_wrapper.dart';

/// Application-wide logging for debugging and production monitoring
final logger = Logger(
  printer: PrettyPrinter(
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

/// Entry point for sport centre booking application
/// Initializes Firebase backend services and state management
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

    // Production consideration: implement proper error handling
    // - User notification of service unavailability
    // - Crash reporting for monitoring
    // - Graceful degradation or app termination
  }

  runApp(const MyApp());
}

/// Root application widget with provider state management and Material theme
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
