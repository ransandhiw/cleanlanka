import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:clean_lanka/common_widgets.dart'; // Import common colors

class SuggestPointScreen extends StatefulWidget {
  const SuggestPointScreen({super.key});

  @override
  State<SuggestPointScreen> createState() => _SuggestPointScreenState();
}

class _SuggestPointScreenState extends State<SuggestPointScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  LatLng? _selectedLatLng;
  bool _isSubmitting = false;
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _locationNameController.dispose();
    _commentsController.dispose();
    _mapController.dispose(); // Dispose the map controller
    super.dispose();
  }

  void _handleMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _selectedLatLng = latlng;
    });
    debugPrint('Map tapped at: Lat: ${latlng.latitude}, Lng: ${latlng.longitude}');
  }

  Future<void> _submitSuggestion() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed.');
      return;
    }

    if (_selectedLatLng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map.')),
      );
      debugPrint('No location selected on map.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to submit a suggestion.')),
        );
        debugPrint('User not logged in. Aborting submission.');
        return;
      }

      debugPrint('Attempting to insert into pickup_points for user: $userId');
      debugPrint('Location Name: ${_locationNameController.text.trim()}');
      debugPrint('Reason: ${_commentsController.text.trim()}');
      debugPrint('Latitude: ${_selectedLatLng!.latitude}');
      debugPrint('Longitude: ${_selectedLatLng!.longitude}');

      await supabase.from('pickup_points').insert({
        'created_by_user_id': userId,
        'location_name': _locationNameController.text.trim(),
        'reason': _commentsController.text.trim(),
        'latitude': _selectedLatLng!.latitude,
        'longitude': _selectedLatLng!.longitude,
      });

      debugPrint('Suggestion submitted successfully to Supabase.'); // Added success print
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suggestion submitted successfully!')),
      );

      // Clear form and reset state
      _formKey.currentState!.reset();
      _locationNameController.clear();
      _commentsController.clear();
      setState(() {
        _selectedLatLng = null;
      });
    } on PostgrestException catch (e) {
      debugPrint('Supabase error: ${e.message}'); // Updated print for PostgrestException
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.message.isNotEmpty
                ? 'Supabase Error: ${e.message}'
                : 'Supabase Error: Unknown. Check RLS policies or table schema for "pickup_points".')),
      );
    } catch (e) {
      debugPrint('Unexpected error: $e'); // Updated print for general errors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Suggest New Point',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: secondaryBlue,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [lightIndigo, Color(0xFFC5CAE9)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      margin: const EdgeInsets.only(bottom: 20.0),
                      child: SizedBox(
                        height: 250, // Height for the map
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: const LatLng(7.8731, 80.7718), // Center of Sri Lanka
                              initialZoom: 7.0,
                              onTap: _handleMapTap,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.clean_lanka',
                              ),
                              if (_selectedLatLng != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedLatLng!,
                                      width: 80.0,
                                      height: 80.0,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40.0,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      _selectedLatLng == null
                          ? 'Tap on the map to select a location.'
                          : 'Selected Location: Lat: ${_selectedLatLng!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLatLng!.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: _selectedLatLng == null ? Colors.grey[700] : primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20.0),
                    TextFormField(
                      controller: _locationNameController,
                      decoration: InputDecoration(
                        labelText: 'Location Name / Description',
                        hintText: 'e.g., Near main bus stop, John\'s Supermarket',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.white.withAlpha((0.7 * 255).round()),
                        prefixIcon: const Icon(Icons.location_city, color: secondaryBlue),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a location name or description.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15.0),
                    TextFormField(
                      controller: _commentsController,
                      decoration: InputDecoration(
                        labelText: 'Comments or Reason (Optional)', // Mapped to 'reason'
                        hintText: 'e.g., Overflowing bin, new residential area',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.white.withAlpha((0.7 * 255).round()),
                        prefixIcon: const Icon(Icons.comment, color: secondaryBlue),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30.0),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitSuggestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 5,
                        shadowColor: primaryGreen.withAlpha((0.4 * 255).round()),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Submit Suggestion',
                              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
