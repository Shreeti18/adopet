import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_app/screens/admin_adoption_screen.dart';
import 'package:pet_app/theme/color.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<Map<String, dynamic>> _loadProfile(User user) async {
    final document = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return document.data() ?? {};
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not log out. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColor.appBgColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColor.appBgColor,
        foregroundColor: AppColor.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: user == null
            ? const Center(
                child: Text('Please log in to view your profile.'),
              )
            : FutureBuilder<Map<String, dynamic>>(
                future: _loadProfile(user),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Could not load your profile.'),
                    );
                  }

                  final profile = snapshot.data ?? {};
                  final name = (profile['name'] ??
                          user.displayName ??
                          'Pet Lover')
                      .toString();
                  final email =
                      (profile['email'] ?? user.email ?? '').toString();
                  final isAdmin =
                      (profile['role'] ?? '').toString().toLowerCase() ==
                          'admin';

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor:
                              AppColor.primary.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.person,
                            size: 48,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: AppColor.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColor.labelColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.person_outline,
                                color: AppColor.primary,
                              ),
                              title: const Text('Profile'),
                              subtitle: const Text(
                                'Your account information',
                              ),
                              trailing:
                                  const Icon(Icons.chevron_right),
                              onTap: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (dialogContext) =>
                                      AlertDialog(
                                    title: const Text('My Profile'),
                                    content: Text(
                                      'Name: $name\n\nEmail: $email',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            if (isAdmin) ...[
                              Divider(
                                height: 1,
                                indent: 55,
                                color: Colors.grey.shade200,
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.admin_panel_settings_outlined,
                                  color: AppColor.primary,
                                ),
                                title: const Text('Admin Panel'),
                                subtitle: const Text(
                                  'Manage adoption requests',
                                ),
                                trailing:
                                    const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminAdoptionScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                            Divider(
                              height: 1,
                              indent: 55,
                              color: Colors.grey.shade200,
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.logout,
                                color: Colors.red,
                              ),
                              title: const Text(
                                'Log out',
                                style: TextStyle(color: Colors.red),
                              ),
                              subtitle: const Text(
                                'Sign out of your account',
                              ),
                              onTap: () => _logout(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Pet App',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColor.labelColor,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}