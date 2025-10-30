import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clean_lanka/common_widgets.dart'; // For colors & styles

class VoteSuggestionsScreen extends StatefulWidget {
  const VoteSuggestionsScreen({super.key});

  @override
  State<VoteSuggestionsScreen> createState() => _VoteSuggestionsScreenState();
}

class _VoteSuggestionsScreenState extends State<VoteSuggestionsScreen> {
  List<Map<String, dynamic>> pickupPoints = [];
  bool isLoading = true;
  String? errorMessage;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = Supabase.instance.client.auth.currentUser;
    _fetchPickupPoints();
  }

  Future<void> _fetchPickupPoints() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // The `votes!left(user_id)` syntax fetches related votes and their user_ids
      // This implicitly assumes a foreign key relationship named 'votes' from 'pickup_points'
      // to the 'votes' table. Ensure your foreign key is set up correctly.
      // The `votes!left(user_id)` part refers to the relationship,
      // and it expects the foreign key column to be named 'point_id' in the 'votes' table
      // as it links back to 'pickup_points'.
      final response = await Supabase.instance.client
          .from('pickup_points')
          .select('point_id, location_name, latitude, longitude, created_at, votes!left(user_id)')
          .order('created_at', ascending: false);

      pickupPoints = (response as List<dynamic>).map((point) {
        final List<dynamic> rawVotes = point['votes'] as List<dynamic>? ?? [];
        final bool hasVoted = _currentUser != null
            ? rawVotes.any((vote) => vote['user_id'] == _currentUser!.id)
            : false;

        return {
          'point_id': point['point_id'],
          'location_name': point['location_name'],
          'latitude': point['latitude'],
          'longitude': point['longitude'],
          'created_at': point['created_at'],
          'vote_count': rawVotes.length,
          'has_voted': hasVoted,
        };
      }).toList();

      // Sort by vote count descending
      pickupPoints.sort((a, b) => (b['vote_count'] as int).compareTo(a['vote_count'] as int));
    } on PostgrestException catch (e) {
      errorMessage = 'Failed to load pickup points: ${e.message}';
      debugPrint(errorMessage);
    } catch (e) {
      errorMessage = 'An unexpected error occurred: $e';
      debugPrint(errorMessage);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleVote(String pointId, bool hasVoted) async {
    if (_currentUser == null) {
      if (!mounted) return; // Guard against context use after async gap
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('You must be logged in to vote.')));
      return;
    }

    try {
      if (hasVoted) {
        // --- FIX: Changed 'suggestion_id' back to 'point_id' for deletion ---
        await Supabase.instance.client
            .from('votes')
            .delete()
            .eq('point_id', pointId) // Correct column name in 'votes' table
            .eq('user_id', _currentUser!.id);
        if (!mounted) return; // Guard against context use after async gap
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vote removed!')),
        );
      } else {
        // --- FIX: Changed 'suggestion_id' back to 'point_id' for insertion ---
        await Supabase.instance.client.from('votes').insert({
          'point_id': pointId, // Correct column name in 'votes' table
          'user_id': _currentUser!.id,
          'voted_at': DateTime.now().toIso8601String(),
        });
        if (!mounted) return; // Guard against context use after async gap
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vote added!')),
        );
      }
      // Refresh the list after voting
      await _fetchPickupPoints();
    } on PostgrestException catch (e) {
      debugPrint('Supabase error: ${e.message}');
      if (!mounted) return; // Guard against context use after async gap
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e) {
      debugPrint('Unexpected error: $e');
      if (!mounted) return; // Guard against context use after async gap
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vote Pickup Points',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: secondaryBlue,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [lightIndigo, Color(0xFFC5CAE9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _fetchPickupPoints,
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
                  : pickupPoints.isEmpty
                      ? const Center(
                          child: Text(
                            'No pickup points found.',
                            style: TextStyle(fontSize: 16, color: darkGray),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: pickupPoints.length,
                          itemBuilder: (context, index) {
                            final point = pickupPoints[index];
                            // Ensure 'created_at' is not null before parsing
                            final DateTime createdAt = DateTime.parse(point['created_at'].toString());
                            final bool hasVoted = point['has_voted'] as bool;
                            final int voteCount = point['vote_count'] as int;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      point['location_name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: secondaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Coordinates: (${point['latitude']}, ${point['longitude']})',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Votes: $voteCount',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: primaryGreen,
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () => _toggleVote(point['point_id'], hasVoted),
                                          icon: Icon(
                                            hasVoted
                                                ? Icons.thumb_up
                                                : Icons.thumb_up_outlined,
                                            color: Colors.white,
                                          ),
                                          label: Text(hasVoted ? 'Voted' : 'Vote'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                hasVoted ? primaryGreen : accentYellow,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Suggested on: ${createdAt.toLocal()}',
                                      style: TextStyle(
                                        fontSize: 12,
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