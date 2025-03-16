import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_app/models/category_model.dart';
import 'package:expense_app/provider/auth_provider.dart';
import 'package:expense_app/provider/category_provider.dart';
import 'package:expense_app/provider/expense_provider.dart';
import 'package:expense_app/provider/theme_provider.dart';
import 'package:expense_app/screen/chart_page.dart';
import 'package:expense_app/screen/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'category_page.dart';
import 'package:intl/intl.dart';


class ExpenseScreen extends ConsumerStatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  String? selectedDate_string; // Store selected date
  final selectedDateProvider = StateProvider<String?>((ref) => null);
  final selectedCategoryProvider = StateProvider<Category?>((ref) => null);
  bool isLoading = false;



  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final categories = ref.watch(categoryProvider);
    final expenses = ref.watch(expenseProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final expenseNotifier = ref.read(expenseProvider.notifier);
    final TextEditingController expenseAmountController = TextEditingController();
    final TextEditingController expenseReasonController = TextEditingController();


    var screenWidth = MediaQuery.of(context).size.width;



    // Ensure selectedDateStr is a valid date
    final selectedDateStr = ref.watch(selectedDateProvider);
    final DateTime? selectedDate = selectedDateStr != null ? DateTime.tryParse(selectedDateStr) : null;

    final filteredExpenses = selectedDate != null
        ? expenses.where((expense) {
      DateTime expenseDate;

      // Check if the expense date is a Firestore Timestamp
      if (expense['date'] is Timestamp) {
        expenseDate = (expense['date'] as Timestamp).toDate();
      } else {
        // Parse the string-based date
        expenseDate = DateTime.tryParse(expense['date'].toString()) ?? DateTime(2000);
      }

      // Compare only the date (ignoring time)
      return DateFormat('yyyy-MM-dd').format(expenseDate) == selectedDateStr;
    }).toList()
        : expenses;





    print("Selected Date: $selectedDate");
    print("Filtered Expenses Count: ${filteredExpenses.length}");



    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // Back button icon
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChartPage()));
          },
        ),
        title: Text("Expense Tracker"),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CategoryPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          width: screenWidth,
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<Category>(
                value: selectedCat,  // selectedCat should be of type `Category?`
                items: categories
                    .map((cat) => DropdownMenuItem(
                  value: cat,  // Store the full object
                  child: Text(cat.name), // Display the category name
                ))
                    .toList(),
                onChanged: (Category? value) {
                  ref.read(selectedCategoryProvider.notifier).state = value; // Store the full Category object
                },
                hint: Text("Select Category"),
              ),

              TextField(
                controller: expenseReasonController,
                decoration: InputDecoration(labelText: "Expense reason"),
              ),
              TextField(
                controller: expenseAmountController,
                decoration: InputDecoration(labelText: "Amount"),
              ),

              ElevatedButton(
                onPressed: () {
                  if (selectedCat != null &&
                      expenseAmountController.text.isNotEmpty &&
                      expenseReasonController.text.isNotEmpty) {
                    ref.read(expenseProvider.notifier).addExpense(
                      selectedCat!.name,
                      double.parse(expenseAmountController.text),
                      expenseReasonController.text.toString(),
                    );
                  }
                },
                child: Text("Add Expense"),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  "Total Expense: \₹${expenseNotifier.totalExpense.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // **Daily expenses (Horizontal Date List)**
              Container(
                height: MediaQuery.of(context).size.height * 0.15,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: expenseNotifier.dailyExpenses.entries.map((entry) {
                    return GestureDetector(
                      onTap: () {
                        ref.read(selectedDateProvider.notifier).state = entry.key;
                        selectedDate_string = entry.key;
                      },
                      child:
                      Row(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.38,
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ref.watch(selectedDateProvider) == entry.key ? Colors.blue : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text("Date: ${entry.key}"),
                                  subtitle: Text("Total: \₹${entry.value.toStringAsFixed(2)}"),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10,)
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: filteredExpenses.length,
                itemBuilder: (context, index) {
                  var expense = filteredExpenses[index];
                  String? expenseId = expense['id'];

                  // Check if the date is a Firestore Timestamp
                  DateTime dateTime;
                  if (expense['date'] is Timestamp) {
                    dateTime = (expense['date'] as Timestamp).toDate();
                  } else {
                    dateTime = DateTime.tryParse(expense['date']) ?? DateTime(2000);
                  }

                  // Format the date
                  String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);

                  return ListTile(
                    title: Text(expense['category']),
                    subtitle: Text("\₹${expense['amount']} - ${expense['description']} at $formattedDate"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit Button
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            showEditDialog(context, expense);
                          },
                        ),

                        // Delete Button
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            deleteExpense(expenseId!); // Pass the expense ID
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),


              if (filteredExpenses.isEmpty)
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    "No expenses found for selected date",
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> logout() async {
    setState(() => isLoading = true);
    final auth = ref.read(authProvider.notifier);
    final error = await auth.logout();

    setState(() => isLoading = false);

    ///if (error == null) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
    //} else {
    ///ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    // }
  }
  void showEditDialog(BuildContext context, Map<String, dynamic> expense) {
    TextEditingController amountController = TextEditingController(text: expense['amount'].toString());
    TextEditingController descriptionController = TextEditingController(text: expense['description']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Amount"),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: "Description"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                updateExpense(expense['id'], amountController.text, descriptionController.text);
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }
  void updateExpense(String? expenseId, String newAmount, String newDescription) async {
    if (expenseId == null) {
      print("Error: Expense ID is null");
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('expenses').doc(expenseId).update({
        'amount': double.parse(newAmount),
        'description': newDescription,
      });
      print("Expense updated successfully!");
      ref.read(expenseProvider.notifier).fetchExpenses();
    } catch (e) {
      print("Error updating expense: $e");
    }
  }
  void deleteExpense(String? expenseId) async {
    if (expenseId == null) {
      print("Error: Expense ID is null");
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('expenses').doc(expenseId).delete();
      ref.read(expenseProvider.notifier).fetchExpenses();
      print("Expense deleted successfully!");
    } catch (e) {
      print("Error deleting expense: $e");
    }
  }


}
