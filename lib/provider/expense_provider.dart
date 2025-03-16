import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_app/provider/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Firebase Auth provider to get the current user
final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final expenseProvider = StateNotifierProvider<ExpenseNotifier, List<Map<String, dynamic>>>((ref) {
  return ExpenseNotifier(ref)..fetchExpenses(); // Fetch expenses on initialization
});

class ExpenseNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref ref;

  ExpenseNotifier(this.ref) : super([]);

  double totalExpense = 0.0; // Store total expense
  Map<String, double> dailyExpenses = {}; // Store expenses per day

  // ✅ Fetch expenses for the logged-in user
  Future<void> fetchExpenses() async {
    try {
      final user = ref.read(authProvider).currentUser;
      if (user == null) return; // Ensure user is logged in

      final querySnapshot = await ref
          .read(firestoreProvider)
          .collection('expenses')
          .where('userId', isEqualTo: user.uid) // Fetch only user's expenses
          .get();

      List<Map<String, dynamic>> expenses = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add Firestore document ID
        return data;
      }).toList();

      // ✅ Calculate total and daily expenses
      totalExpense = 0.0;
      dailyExpenses = {};

      for (var expense in expenses) {
        double amount = (expense['amount'] as num).toDouble();
        totalExpense += amount;

        String dateKey =
        (expense['date'] as Timestamp).toDate().toLocal().toString().split(" ")[0];

        dailyExpenses.update(dateKey, (value) => value + amount, ifAbsent: () => amount);
      }

      state = expenses; // Update state
    } catch (e) {
      print("Error fetching expenses: $e");
    }
  }

  // ✅ Add expense with user ID
  Future<void> addExpense(String category, double amount, String description) async {
    try {
      final user = ref.read(authProvider).currentUser;
      if (user == null) return; // Ensure user is logged in

      await ref.read(firestoreProvider).collection('expenses').add({
        'category': category,
        'amount': amount,
        'description': description,
        'date': Timestamp.now(),
        'userId': user.uid, // Associate expense with the user
      });

      fetchExpenses(); // Refresh state after adding
    } catch (e) {
      print("Error adding expense: $e");
    }
  }
}
