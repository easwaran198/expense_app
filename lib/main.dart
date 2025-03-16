import 'package:expense_app/provider/theme_provider.dart';
import 'package:expense_app/screen/chart_page.dart';
import 'package:expense_app/screen/expense_page.dart';
import 'package:expense_app/screen/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final String? userId = prefs.getString('userId');

  runApp(ProviderScope(child: MyApp(isLoggedIn: userId != null)));
}

class MyApp extends ConsumerWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),  // Light Theme
      darkTheme: ThemeData.dark(), // Dark Theme
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: isLoggedIn ? ChartPage() : LoginPage(),
    );
  }
}
