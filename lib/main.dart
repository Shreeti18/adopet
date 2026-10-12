
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/root_app.dart';
import 'screens/auth_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'theme/color.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetHub',
      theme: ThemeData(
        primaryColor: AppColor.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E78D8),
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.hasError) {
            debugPrint(
              'AUTH STATE ERROR: ${authSnapshot.error}',
            );

            return const AuthScreen();
          }

          if (authSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const LoadingScreen();
          }

          final user = authSnapshot.data;

          if (user == null) {
            debugPrint('AUTH GATE: No signed-in user.');
            return const AuthScreen();
          }

          debugPrint('AUTH GATE: Signed-in UID = ${user.uid}');
          debugPrint('AUTH GATE: Email = ${user.email}');

          return FutureBuilder<
              DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const LoadingScreen();
              }

              if (userSnapshot.hasError) {
                debugPrint(
                  'PROFILE ERROR: ${userSnapshot.error}',
                );

                return ProfileLoadErrorScreen(
                  message:
                      'Could not load your profile. Check your '
                      'internet connection and Firestore rules.',
                  onRetry: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AuthScreen(),
                      ),
                    );
                  },
                  onLogout: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                );
              }

              if (!userSnapshot.hasData ||
                  !userSnapshot.data!.exists) {
                debugPrint(
                  'PROFILE ERROR: No users/${user.uid} document.',
                );

                return ProfileLoadErrorScreen(
                  message:
                      'Your account is signed in, but its profile '
                      'was not found in Firestore. Check that the '
                      'users document ID matches your Firebase '
                      'Authentication UID.',
                  onRetry: () async {
                    // Refresh the widget tree to retry the lookup.
                    (context as Element).markNeedsBuild();
                  },
                  onLogout: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                );
              }

              final profile = userSnapshot.data!.data()!;
              final role = (profile['role'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();

              debugPrint('PROFILE DEBUG: UID = ${user.uid}');
              debugPrint('PROFILE DEBUG: Exists = true');
              debugPrint('PROFILE DEBUG: Role = "$role"');

              if (role == 'admin') {
                return const AdminDashboardScreen();
              }

              if (role == 'user') {
                return const RootApp();
              }

              debugPrint(
                'PROFILE ERROR: Invalid or missing role "$role".',
              );

              return ProfileLoadErrorScreen(
                message:
                    'Your profile has an invalid or missing role. '
                    'In Firestore, set role to "admin" or "user".',
                onRetry: () {
                  (context as Element).markNeedsBuild();
                },
                onLogout: () async {
                  await FirebaseAuth.instance.signOut();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8E78D8),
        ),
      ),
    );
  }
}

class ProfileLoadErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onLogout;

  const ProfileLoadErrorScreen({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 52,
                  color: Color(0xFF8E78D8),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load your profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () async {
                    await onLogout();
                  },
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
