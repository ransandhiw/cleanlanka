import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clean_lanka/common_widgets.dart'; // For common colors
import 'package:clean_lanka/login_screen.dart'; // For logout navigation

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  String? _fullName;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _currentUser = Supabase.instance.client.auth.currentUser;
      if (_currentUser != null) {
        // Fetch user metadata for full name
        // Supabase stores user metadata in auth.users.raw_user_meta_data
        // You can access it via currentUser.user_metadata
        _fullName = _currentUser!.userMetadata?['full_name'] as String?;
      } else {
        _errorMessage = 'User not logged in.';
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _errorMessage = 'Failed to load profile data.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      debugPrint('User signed out successfully from profile screen.');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } on AuthException catch (e) {
      debugPrint('Error signing out: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.message}')),
      );
    } catch (e) {
      debugPrint('An unexpected error occurred during sign out: ${e.toString()}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: secondaryBlue,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [lightIndigo, Color(0xFFC5CAE9)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryGreen))
            : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Name: ${_fullName ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                Text(
                                  'Email: ${_currentUser?.email ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Implement Edit Profile functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit Profile functionality coming soon!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            elevation: 5,
                            shadowColor: secondaryBlue.withAlpha((0.4 * 255).round()),
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 15.0),
                        ElevatedButton(
                          onPressed: _signOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            elevation: 5,
                            shadowColor: Colors.redAccent.withAlpha((0.4 * 255).round()),
                          ),
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
