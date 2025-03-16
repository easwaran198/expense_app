import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_app/provider/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final expenseProvider = StateNotifierProvider<ExpenseNotifier, List<Map<String, dynamic>>>((ref) {
  return ExpenseNotifier(ref)..fetchExpenses(); // Fetch expenses on initialization
});

class ExpenseNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref ref;

  ExpenseNotifier(this.ref) : super([]);

  double totalExpense = 0.0; // Store total expense
  Map<String, double> dailyExpenses = {}; // Store expenses per day

  Future<void> fetchExpenses() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        state = []; // Clear state if no user is logged in
        return;
      }

      final querySnapshot = await ref.read(firestoreProvider)
          .collection('expenses')
          .where('userId', isEqualTo: userId) // Filter expenses by userId
          .get();

      List<Map<String, dynamic>> expenses = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add Firestore document ID
        return data;
      }).toList();

      // Calculate total and daily expenses
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





  Future<void> addExpense(String category, double amount, String description) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid; // Get the userId
      await ref.read(firestoreProvider).collection('expenses').add({
        'category': category,
        'amount': amount,
        'description': description,
        'date': Timestamp.now(),
        'userId': userId, // Associate the expense with the user
      });

      fetchExpenses(); // Refresh state after adding
    } catch (e) {
      print("Error adding expense: $e");
    }
  }

}
