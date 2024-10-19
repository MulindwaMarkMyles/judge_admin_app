import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Set<String>> getAllUserDocIds() async {
    try {
      final userCollection = _db.collectionGroup('categories');
      final querySnapshot = await userCollection.get();

      // Use a Set to store unique user IDs
      Set<String> userIds = {};

      for (var doc in querySnapshot.docs) {
        // Extract the user ID from the parent path
        final userId = doc.reference.parent.parent?.id;
        if (userId != null) {
          userIds.add(userId); // Add user ID to the Set
        }
      }

      return userIds;
    } catch (e) {
      print("Error fetching user doc IDs: $e");
      return {};
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

      // Iterate through each student to get total marks
      for (var studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();

        // Calculate total marks, ignoring the 'number' field
        int totalMarks = studentData.entries
            .where((entry) => entry.key != 'number')
            .fold(0, (sum, entry) => sum + (entry.value as int? ?? 0));

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

// Fetch top contestants for all categories across multiple users
  Future<List<Map<String, dynamic>>> fetchTopContestantsForAllUsers(
      Set<String> userIds) async {
    try {
      // Parallel fetching for all users
      List<Future<List<Map<String, dynamic>>>> userFutures =
          userIds.map((userId) {
        return _fetchTopContestantsForAllCategories(userId);
      }).toList();

      // Wait for all user results and flatten into a single list
      List<List<Map<String, dynamic>>> allUserResults =
          await Future.wait(userFutures);
      List<Map<String, dynamic>> allContestants =
          allUserResults.expand((result) => result).toList();

      print("done....");
      return allContestants;
    } catch (e) {
      print("Error fetching contestants: $e");
      return [];
    }
  }

// Fetch top contestants for all categories for a specific user
  Future<List<Map<String, dynamic>>> _fetchTopContestantsForAllCategories(
      String userId) async {
    try {
      // Get all categories for the user
      final categoriesSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      // Fetch top contestants in parallel for each category
      List<Future<List<Map<String, dynamic>>>> futures =
          categoriesSnapshot.docs.map((doc) {
        final categoryName = doc['name']; // Extract category name
        return _fetchTopContestantsForCategory(userId, doc.id, categoryName);
      }).toList();

      // Wait for all results and flatten into a single list
      List<List<Map<String, dynamic>>> allResults = await Future.wait(futures);
      return allResults.expand((result) => result).toList();
    } catch (e) {
      print("Error fetching contestants for user $userId: $e");
      return [];
    }
  }
}
