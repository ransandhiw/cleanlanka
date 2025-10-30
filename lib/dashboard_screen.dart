import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clean_lanka/common_widgets.dart'; // Import common widgets for colors
import 'package:clean_lanka/login_screen.dart'; // Import login screen for logout navigation
import 'package:clean_lanka/suggest_point_screen.dart'; // New import
import 'package:clean_lanka/app_notices_screen.dart'; // UPDATED IMPORT for the renamed AppNoticesScreen
import 'package:clean_lanka/profile_screen.dart'; // New import
import 'package:clean_lanka/vote_suggestions_screen.dart'; // New import
// Removed: import 'package:intl/intl.dart'; // REMOVED UNUSED IMPORT
//import 'package:clean_lanka/push_notifications_page.dart'; // <--- UNCOMMENTED/ADDED: Import the push notifications test page

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userArea = "Colombo, Sri Lanka";
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;
  String? errorMessage;
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    debugPrint('DashboardScreen: initState called.');
    _fetchSchedules();

    // Initialize _widgetOptions with the refresh callback
    _widgetOptions = <Widget>[
      _SchedulesContent(
        schedules: schedules,
        isLoading: isLoading,
        errorMessage: errorMessage,
        userArea: userArea,
        onRefresh: _fetchSchedules, // Pass the refresh function
      ),
      const SuggestPointScreen(),
      const AppNoticesScreen(),
      const ProfileScreen(),
      const VoteSuggestionsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    debugPrint('BottomNavigationBar: Item tapped at index $index.');
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _fetchSchedules() async {
    debugPrint('Fetching schedules...');
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }
      debugPrint('isLoading set to true, errorMessage set to null.');

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('waste_schedules')
          .select()
          .order('collection_day', ascending: true);

      debugPrint('Supabase Response Raw: $response');

      schedules = List<Map<String, dynamic>>.from(response);

      final List<String> daysOrder = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      schedules.sort((a, b) {
        final String dayA = a['collection_day']?.toString() ?? '';
        final String dayB = b['collection_day']?.toString() ?? '';
        return daysOrder.indexOf(dayA).compareTo(daysOrder.indexOf(dayB));
      });

      debugPrint('Schedules fetched successfully. Count: ${schedules.length}');
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException fetching schedules: ${e.message}');
      errorMessage = 'Supabase Error: ${e.message} (Code: ${e.code}). Please check RLS or table name.';
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
      errorMessage = 'Failed to load schedules. Please check your connection or Supabase setup: $e';
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          debugPrint('isLoading set to false.');
          // Update the schedules content widget with the latest data
          _widgetOptions[0] = _SchedulesContent(
            schedules: schedules,
            isLoading: isLoading,
            errorMessage: errorMessage,
            userArea: userArea,
            onRefresh: _fetchSchedules,
          );
          debugPrint('_SchedulesContent updated within _widgetOptions.');
        });
      }
    }
  }

  Future<void> _signOut() async {
    debugPrint('Attempting to sign out...');
    try {
      await Supabase.instance.client.auth.signOut();
      debugPrint('User signed out successfully.');
      if (!mounted) {
        debugPrint('Context not mounted after sign out attempt. Aborting navigation.');
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
      debugPrint('Navigated to LoginScreen.');
    } on AuthException catch (e) {
      debugPrint('Error signing out (AuthException): ${e.message}');
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
    debugPrint('DashboardScreen: build method called. Selected index: $_selectedIndex');
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Clean Lanka',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: secondaryBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            tooltip: 'Push Notification Test',
            onPressed: () {
              Navigator.pushNamed(context, '/push_notification_test');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_location_alt),
            label: 'Suggest Point',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote),
            label: 'Vote',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}

class _SchedulesContent extends StatelessWidget {
  final List<Map<String, dynamic>> schedules;
  final bool isLoading;
  final String? errorMessage;
  final String userArea;
  final Future<void> Function() onRefresh; // New parameter for the refresh function

  const _SchedulesContent({
    required this.schedules,
    required this.isLoading,
    required this.errorMessage,
    required this.userArea,
    required this.onRefresh, // Added super.key to the constructor
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('_SchedulesContent: build method called. Is Loading: $isLoading, Error: $errorMessage, Schedules count: ${schedules.length}');

    // Wrap the content in a RefreshIndicator
    return RefreshIndicator(
      onRefresh: onRefresh, // This now points to the _fetchSchedules method
      color: primaryGreen, // Set the color of the refresh indicator
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8EAF6),
              Color(0xFFC5CAE9),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 20.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Location: $userArea',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Your current waste collection area.',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              isLoading
                  ? const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: primaryGreen),
                      ),
                    )
                  : errorMessage != null
                      ? Expanded(
                          child: Center(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : schedules.isEmpty
                          ? const Expanded(
                              child: Center(
                                child: Text(
                                  'No schedules available yet for your area. Please add some in Supabase.',
                                  style: TextStyle(fontSize: 16, color: darkGray),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : Expanded(
                              child: ListView.builder(
                                itemCount: schedules.length,
                                itemBuilder: (context, index) {
                                  final schedule = schedules[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                    color: primaryGreen.withAlpha((0.1 * 255).round()),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            schedule['collection_day']?.toString() ?? 'N/A',
                                            style: const TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                              color: primaryGreen,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            '${schedule['collection_time']?.toString() ?? 'N/A'} - ${schedule['area']?.toString() ?? 'N/A'}',
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ],
          ),
        ),
      ),
    );
  }
}