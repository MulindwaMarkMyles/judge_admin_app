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
  
  Future<int> getTotalNoOfJudges() async {
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

      return userIds.length;
    } catch (e) {
      print("Error fetching length.");
      return 0;
    }
  }

  // Fetch top contestants for a category
  Future<List<Map<String, dynamic>>> _fetchTopContestantsForCategory(
    String userId,
    String categoryId,
    String categoryName,
  ) async {
    try {

      final studentsSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(categoryId)
          .collection('students')
          .get();


      // Map to aggregate scores by contestant number
      Map<int, int> aggregatedScores = {};

      for (var studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();

        final int contestantNumber = studentData['number'];
        int totalMarks = studentData.entries
            .where((entry) => entry.key != 'number')
            .fold(0, (sum, entry) => sum + (entry.value as int? ?? 0));


        // Aggregate scores for each contestant
        aggregatedScores.update(
          contestantNumber,
          (existingMarks) => existingMarks + totalMarks,
          ifAbsent: () => totalMarks,
        );
      }


      // Convert aggregated scores to a list of contestant maps
      List<Map<String, dynamic>> contestants =
          aggregatedScores.entries.map((entry) {
        return {
          'number': entry.key,
          'totalMarks': entry.value,
          'category': categoryName,
        };
      }).toList();

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
      print("Fetching contestants for all users: $userIds");

      // Parallel fetching for all users' categories
      List<Future<List<Map<String, dynamic>>>> userFutures =
          userIds.map((userId) {
        return _fetchTopContestantsForAllCategories(userId);
      }).toList();

      // Wait for all user results
      List<List<Map<String, dynamic>>> allUserResults =
          await Future.wait(userFutures);

      // Flatten the results into a single list
      List<Map<String, dynamic>> allContestants =
          allUserResults.expand((result) => result).toList();


      // Aggregate scores by contestant number across users
      Map<int, Map<String, dynamic>> aggregatedContestants = {};

      for (var contestant in allContestants) {
        int number = contestant['number'];
        int totalMarks = contestant['totalMarks'];
        String category = contestant['category'];

        if (aggregatedContestants.containsKey(number)) {
          // If contestant already exists, update the total marks
          aggregatedContestants[number]!['totalMarks'] += totalMarks;
        } else {
          // Otherwise, add a new entry for the contestant
          aggregatedContestants[number] = {
            'number': number,
            'totalMarks': totalMarks,
            'category': category, // Optional: keep track of the category
          };
        }
      }

      // Convert the aggregated map back into a list
      List<Map<String, dynamic>> finalContestants =
          aggregatedContestants.values.toList();

      // Sort contestants by totalMarks in descending order
      finalContestants
          .sort((a, b) => b['totalMarks'].compareTo(a['totalMarks']));

      return finalContestants;
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
