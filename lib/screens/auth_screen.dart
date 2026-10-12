
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/color.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isAdminLogin = false;
  bool _isLoading = false;
  bool _hidePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'network-request-failed':
        return 'Check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled in Firebase.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      debugPrint('LOGIN DEBUG: Starting authentication.');
      debugPrint('LOGIN DEBUG: Email = $email');
      debugPrint('LOGIN DEBUG: Admin mode = $_isAdminLogin');

      UserCredential credential;

      if (_isLogin) {
        credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final name = _nameController.text.trim();
        await credential.user!.updateDisplayName(name);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'uid': credential.user!.uid,
          'name': name,
          'email': email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final user = credential.user;

      if (user == null) {
        throw Exception('Firebase returned no authenticated user.');
      }

      debugPrint('LOGIN DEBUG: UID = ${user.uid}');
      debugPrint('LOGIN DEBUG: Authenticated = true');

      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final profileExists = userDocument.exists;
      final role = (userDocument.data()?['role'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      debugPrint('LOGIN DEBUG: Profile exists = $profileExists');
      debugPrint('LOGIN DEBUG: Role = "$role"');

      if (!profileExists) {
        debugPrint(
          'LOGIN DEBUG: Missing Firestore document users/${user.uid}',
        );

        await FirebaseAuth.instance.signOut();

        if (mounted) {
          _showMessage(
            'Your Firestore profile is missing. Check that users/${user.uid} '
            'exists and its document ID matches this UID.',
          );
        }
        return;
      }

      if (role != 'admin' && role != 'user') {
        debugPrint('LOGIN DEBUG: Invalid role "$role".');

        await FirebaseAuth.instance.signOut();

        if (mounted) {
          _showMessage(
            'Your Firestore role is missing or invalid. Set it to '
            '"admin" or "user".',
          );
        }
        return;
      }

      if (_isAdminLogin && role != 'admin') {
        debugPrint('LOGIN DEBUG: Admin login rejected.');

        await FirebaseAuth.instance.signOut();

        if (mounted) {
          _showMessage(
            'This account is not authorized as an admin.',
          );
        }
        return;
      }

      if (!_isAdminLogin && role == 'admin') {
        debugPrint('LOGIN DEBUG: Admin account used in user mode.');

        await FirebaseAuth.instance.signOut();

        if (mounted) {
          _showMessage(
            'Please use Admin Login for the admin account.',
          );
        }
        return;
      }

      debugPrint('LOGIN DEBUG: Role validation successful.');
      debugPrint('LOGIN DEBUG: main.dart will open the correct screen.');
    } on FirebaseAuthException catch (error) {
      debugPrint('LOGIN AUTH ERROR: ${error.code}');
      debugPrint('LOGIN AUTH MESSAGE: ${error.message}');

      if (mounted) {
        _showMessage(_friendlyError(error));
      }
    } catch (error, stackTrace) {
      debugPrint('LOGIN ERROR: $error');
      debugPrint('LOGIN STACK TRACE: $stackTrace');

      // If signup failed after creating the account, sign out so
      // the app does not proceed with a partially created profile.
      if (!_isLogin &&
          FirebaseAuth.instance.currentUser != null) {
        try {
          await FirebaseAuth.instance.signOut();
        } catch (signOutError) {
          debugPrint('SIGN-OUT ERROR: $signOutError');
        }
      }

      if (mounted) {
        _showMessage(
          'Login could not be completed. Check the debug console '
          'for the exact error.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _switchMode() {
    setState(() {
      _isAdminLogin = !_isAdminLogin;
      _isLogin = true;
      _errorMessage = null;
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF8E78D8);

    return Scaffold(
      backgroundColor: AppColor.appBgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      _isAdminLogin
                          ? Icons.admin_panel_settings_rounded
                          : Icons.pets_rounded,
                      size: 76,
                      color: purple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isAdminLogin
                          ? 'Admin Login'
                          : (_isLogin
                              ? 'Welcome Back!'
                              : 'Find Your New Best Friend'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAdminLogin
                          ? 'Sign in with the authorized admin account.'
                          : (_isLogin
                              ? 'Log in to continue your pet adoption journey.'
                              : 'Create an account to get started.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (!_isLogin && !_isAdminLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (!_isLogin &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Please enter your name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(value.trim())) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password.';
                        }
                        if (!_isLogin && value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isAdminLogin
                                  ? 'Admin Login'
                                  : (_isLogin ? 'Log In' : 'Create Account'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    if (!_isAdminLogin) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _errorMessage = null;
                                });
                              },
                        child: Text(
                          _isLogin
                              ? "Don't have an account? Sign up"
                              : 'Already have an account? Log in',
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    const Divider(),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _switchMode,
                      icon: Icon(
                        _isAdminLogin
                            ? Icons.person_outline
                            : Icons.admin_panel_settings_outlined,
                      ),
                      label: Text(
                        _isAdminLogin
                            ? 'Back to User Login'
                            : 'Admin Login',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
