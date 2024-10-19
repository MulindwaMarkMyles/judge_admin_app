import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch all users from the Firestore database
  Future<void> listAllUsers() async {
    try {
      // Get all users from the 'users' collection
      final usersSnapshot = await _db.collection('users').get();

      // Iterate through each user document and print its data
      for (var userDoc in usersSnapshot.docs) {
        print('User ID: ${userDoc.id} => Data: ${userDoc.data()}');
      }
      print("done.");
    } catch (e) {
      print('Error listing users: $e');
    }
  }

  // Fetch top contestants for all categories with parallelization
  Future<List<Map<String, dynamic>>> fetchTopContestantsForAllCategories(
      String userId) async {
    try {
      // Get all categories
      final categoriesSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      // Parallel fetching of contestants for each category
      List<Future<List<Map<String, dynamic>>>> futures =
          categoriesSnapshot.docs.map((doc) {
        final categoryName =
            doc['name']; // Ensure we extract category name correctly
        return _fetchTopContestantsForCategory(userId, doc.id, categoryName);
      }).toList();

      // Wait for all results to complete
      List<List<Map<String, dynamic>>> allResults = await Future.wait(futures);

      // Flatten the results into a single list
      return allResults.expand((result) => result).toList();
    } catch (e) {
      print("Error fetching contestants: $e");
      return [];
    }
  }

  // Fetch top contestants from all users
  Future<List<Map<String, dynamic>>> fetchTopContestantsForAllUsers() async {
    try {
      // Fetch all users from Firestore
      final usersSnapshot = await _db.collection('users').get();

      // Fetch contestants for each user in parallel
      List<Future<List<Map<String, dynamic>>>> futures = usersSnapshot.docs
          .map(
            (userDoc) => fetchTopContestantsForAllCategories(userDoc.id),
          )
          .toList();

      // Wait for all contestant lists and flatten the results
      final List<List<Map<String, dynamic>>> allResults =
          await Future.wait(futures);
      print(allResults.expand((result) => result).toList());
      return allResults.expand((result) => result).toList();
    } catch (e) {
      print("Error fetching contestants: $e");
      return [];
    }
  }

  // Fetch top contestants for a single category
  Future<List<Map<String, dynamic>>> _fetchTopContestantsForCategory(
    String userId,
    String categoryId,
    String categoryName,
  ) async {
    try {
      // Fetch all students in the given category
      final studentsSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(categoryId)
          .collection('students')
          .get();

      List<Map<String, dynamic>> contestants = [];

      // Iterate through each student to get total marks directly from the student document
      for (var studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();

        // Calculate total marks from specified fields
        int totalMarks = 0;

        // Loop through all fields in the student data, excluding 'number' (or any other field you want to skip)
        for (var entry in studentData.entries) {
          if (entry.key != 'number') {
            totalMarks += entry.value as int? ??
                0; // Safely add the marks, defaulting to 0 if null
          }
        }

        // Add student data to the contestants list
        contestants.add({
          'number': studentData['number'],
          'totalMarks': totalMarks,
          'category': categoryName,
        });
      }

      // Sort contestants by totalMarks in descending order and return top 5
      contestants.sort((a, b) => b['totalMarks'].compareTo(a['totalMarks']));
      return contestants.take(5).toList();
    } catch (e) {
      print("Error fetching contestants for category $categoryName: $e");
      return [];
    }
  }
}
