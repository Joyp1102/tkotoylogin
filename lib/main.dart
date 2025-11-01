import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'login_signup_page.dart';
import 'home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all uncaught errors so we can surface them in UI.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // ignore: avoid_print
    print('FlutterError: ${details.exceptionAsString()}');
  };

  runZonedGuarded(() async {
    runApp(const _BootScreen());              // show something immediately

    // Try to init Firebase, but don't block UI forever.
    try {
      // Logs to console so you can see progress in Run window.
      // ignore: avoid_print
      print('Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 8));

      // ignore: avoid_print
      print('Firebase initialized. Launching app...');
      runApp(const TkoApp());
    } on TimeoutException catch (_) {
      runApp(const _InitErrorScreen(
        message: 'Firebase initialization timed out.\n'
            'Check Internet, google-services.json, Play Services.',
      ));
    } catch (e, st) {
      // ignore: avoid_print
      print('Firebase init error: $e\n$st');
      runApp(_InitErrorScreen(message: e.toString()));
    }
  }, (e, st) {
    // ignore: avoid_print
    print('Uncaught zone error: $e\n$st');
  });
}

// Shows while Firebase is initializing.
class _BootScreen extends StatelessWidget {
  const _BootScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF7F2EC),
        colorSchemeSeed: const Color(0xFFFF6A00),
      ),
      home: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

// Shown if init fails or times out (so you aren't stuck on splash).
class _InitErrorScreen extends StatelessWidget {
  final String message;
  const _InitErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF7F2EC),
        colorSchemeSeed: const Color(0xFFFF6A00),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Startup Error')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  // Quick retry: re-run main zone (hot restart is best).
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TkoApp extends StatelessWidget {
  const TkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TKO Loyalty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF6A00),
        scaffoldBackgroundColor: const Color(0xFFF7F2EC),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return _InitErrorScreen(message: 'Auth stream error: ${snap.error}');
        }
        if (snap.hasData) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}
