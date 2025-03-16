import 'package:expense_app/provider/auth_provider.dart';
import 'package:expense_app/screen/chart_page.dart';
import 'package:expense_app/screen/expense_page.dart';
import 'package:expense_app/screen/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class LoginPage extends ConsumerStatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    setState(() => isLoading = true);
    final auth = ref.read(authProvider.notifier);
    final error = await auth.login(emailController.text, passwordController.text);

    setState(() => isLoading = false);

    if (error == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChartPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: login, child: Text('Login')),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RegisterPage()));
              },
              child: Text('Do you dont have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
