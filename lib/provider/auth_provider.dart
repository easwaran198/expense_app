import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// FirebaseAuth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Authentication state provider
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) => AuthNotifier(ref));

class AuthNotifier extends StateNotifier<User?> {
  final Ref ref;

  AuthNotifier(this.ref) : super(null) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null) {
        state = ref.read(firebaseAuthProvider).currentUser;
      }
    } catch (e) {
      print("Error loading user: $e");
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final userCredential = await ref.read(firebaseAuthProvider).signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveUser(userCredential.user);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      final userCredential = await ref.read(firebaseAuthProvider).createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveUser(userCredential.user);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _saveUser(User? user) async {
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.uid);
      state = user;
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(firebaseAuthProvider).signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      state = null;
    } catch (e) {
      print("Error logging out: $e");
    }
  }
}
