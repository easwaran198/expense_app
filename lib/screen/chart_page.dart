import 'package:expense_app/provider/expense_provider.dart';
import 'package:expense_app/provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_app/screen/expense_page.dart';
import 'package:fl_chart/fl_chart.dart';


class ChartPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final expenses = ref.watch(expenseProvider); // Fetch expenses

    // Group expenses by category
    Map<String, double> categoryExpenses = {};
    for (var expense in expenses) {
      String category = expense['category'];
      double amount = (expense['amount'] as num).toDouble();
      categoryExpenses.update(category, (value) => value + amount, ifAbsent: () => amount);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Expense Tracker"),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child:
              PieChart(
                PieChartData(
                  sections: categoryExpenses.entries.map((entry) {
                    return PieChartSectionData(
                      color: Colors.primaries[entry.key.hashCode % Colors.primaries.length],
                      value: entry.value,
                      title: entry.key,
                      radius: 60,
                      titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ExpenseScreen()));
              },
              icon: Icon(Icons.arrow_back),
              label: Text("Goto to Expenses"),
            ),
          ],
        ),
      ),
    );
  }
}
