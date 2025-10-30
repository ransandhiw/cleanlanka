import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clean_lanka/common_widgets.dart'; // For common colors

class AppNoticesScreen extends StatefulWidget { // Renamed class
  const AppNoticesScreen({super.key});

  @override
  State<AppNoticesScreen> createState() => _AppNoticesScreenState(); // Renamed state class
}

class _AppNoticesScreenState extends State<AppNoticesScreen> { // Renamed state class
  List<Map<String, dynamic>> notices = []; // Changed variable name to 'notices'
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotices(); // Changed method call
  }

  Future<void> _fetchNotices() async { // Changed method name
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      // --- IMPORTANT CHANGE: Querying the 'notices' table ---
      final response = await Supabase.instance.client
          .from('notices') // Changed from 'notifications' to 'notices'
          .select()
          .order('posted_at', ascending: false); // Changed from 'sent_at' to 'posted_at'

      notices = List<Map<String, dynamic>>.from(response); // Using 'notices' list
    } on PostgrestException catch (e) {
      debugPrint('Supabase error fetching notices: ${e.message}');
      errorMessage = 'Failed to load notices: ${e.message}';
    } catch (e) {
      debugPrint('Unexpected error fetching notices: $e');
      errorMessage = 'An unexpected error occurred. Please try again.';
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Announcements', // Changed AppBar title
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
        child: RefreshIndicator(
          onRefresh: _fetchNotices, // Changed method call for pull to refresh
          color: primaryGreen,
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryGreen))
              : errorMessage != null
                  ? Center(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : notices.isEmpty // Using 'notices' list
                      ? const Center(
                          child: Text(
                            'No announcements yet.', // Updated empty message
                            style: TextStyle(fontSize: 16, color: darkGray),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: notices.length, // Using 'notices' list
                          itemBuilder: (context, index) {
                            final notice = notices[index]; // Changed variable name
                            final DateTime createdAt =
                                DateTime.parse(notice['posted_at']); // Changed from 'sent_at' to 'posted_at'
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notice['title']?.toString() ?? 'No Title', // Using 'notice' variable
                                      style: const TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                        color: secondaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      notice['message']?.toString() ?? 'No Message', // Using 'notice' variable
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      '${createdAt.toLocal().toIso8601String().split('.')[0].replaceFirst('T', ' ')}',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
