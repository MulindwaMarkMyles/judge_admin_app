import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:judge_admin_app/database.dart';

class Homescreen extends StatefulWidget {
  final String username;
  Homescreen({super.key, required this.username});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  List<Map<String, dynamic>> _contestants = [];
  bool _isRefreshing = false;
  final FirestoreService _fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    print('Fetching contestants...');
    _refreshTopContestants();
    _fs.listAllUsers();
  }

  Future<void> _refreshTopContestants() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final contestants = await _fs.fetchTopContestantsForAllUsers();
      if (contestants.isEmpty) {
        print('No contestants found.');
      } else {
        print('Loaded contestants: $contestants');
      }

      setState(() {
        _contestants = contestants;
      });
    } catch (e) {
      print('Error during contestant refresh: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing: $e')),
      );
    }

    // Simulate a delay to avoid UI flickering
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isRefreshing = false;
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupContestantsByCategory() {
    Map<String, List<Map<String, dynamic>>> groupedContestants = {};

    for (var contestant in _contestants) {
      String category = contestant['category'];
      if (!groupedContestants.containsKey(category)) {
        groupedContestants[category] = [];
      }
      groupedContestants[category]!.add(contestant);
    }

    return groupedContestants;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "The Top Scorers for each category based on different judges.",
                style: GoogleFonts.poppins(
                  fontSize: 18.0,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            _isRefreshing
                ? Center(child: CircularProgressIndicator())
                : _contestants.isEmpty
                    ? Center(
                        child: Text(
                          'No contestants available.',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        physics: const NeverScrollableScrollPhysics(),
                        children:
                            _groupContestantsByCategory().entries.map((entry) {
                          String category = entry.key;
                          List<Map<String, dynamic>> contestants = entry.value;

                          return ExpansionTile(
                            title: Text(
                              category,
                              style: GoogleFonts.poppins(
                                  fontSize: 25.0, fontWeight: FontWeight.w600),
                            ),
                            children: contestants.map((contestant) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.amber[400],
                                  child: Text(
                                    '${contestants.indexOf(contestant) + 1}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  'Contestant ${contestant['number']}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  'Score: ${contestant['totalMarks']}/100',
                                  style: GoogleFonts.poppins(fontSize: 14.0),
                                ),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _refreshTopContestants,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
