import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:judge_admin_app/database.dart';

class Homescreen extends StatefulWidget {
  final String username;
  const Homescreen({super.key, required this.username});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  List<Map<String, dynamic>> _contestants = [];
  bool _isRefreshing = false;
  final FirestoreService _fs = FirestoreService();
  int no_of_judges = 0;

  @override
  void initState() {
    super.initState();
    _refreshTopContestants();
    getJudges();
  }

  Future<void> getJudges() async {
    int judges = await _fs.getTotalNoOfJudges();
    setState(() {
      no_of_judges = judges;
    });
  }

  Future<void> _refreshTopContestants() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      getJudges();
      final userIds = await _fs.getAllUserDocIds();

      final contestants = await _fs.fetchTopContestantsForAllUsers(userIds);

      setState(() {
        _contestants = contestants;
      });
    } catch (e) {
      print("Error in refreshing: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing: $e')),
      );
    }

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
      backgroundColor: Colors.amber[50],
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Text(
                "Hey, ${widget.username}",
                style: GoogleFonts.poppins(
                  fontSize: 29.0,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                "\nThe Top Scorers for each category based on different judges.",
                style: GoogleFonts.poppins(
                  fontSize: 18.0,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            _isRefreshing
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  )
                : _contestants.isEmpty
                    ? Center(
                        child: Text(
                          'No contestants available.',
                          style: GoogleFonts.poppins(
                              fontSize: 16.0, color: Colors.black54),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        physics: const NeverScrollableScrollPhysics(),
                        children: _groupContestantsByCategory()
                            .entries
                            .expand((entry) => [
                                  Card(
                                    margin: const EdgeInsets.all(0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    elevation: 4.0,
                                    child: ExpansionTile(
                                      title: Text(
                                        entry.key,
                                        style: GoogleFonts.poppins(
                                          fontSize: 22.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      children: entry.value.map((contestant) {
                                        return ListTile(
                                          contentPadding: const EdgeInsets.all(
                                              16.0), // Corrected padding
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                          ),
                                          tileColor: Colors.amber[100],
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.amber[400],
                                            child: Text(
                                              '${entry.value.indexOf(contestant) + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16.0,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            'Contestant ${contestant['number']}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Score: ${((contestant['totalMarks'] / (100 * no_of_judges)) * 100).toStringAsFixed(2)} / 100',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14.0,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(
                                      height: 16), // Add space between tiles
                                ])
                            .toList(),
                      ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: _refreshTopContestants,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  elevation: 5.0,
                ),
                child: Text(
                  'Refresh',
                  style: GoogleFonts.poppins(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
